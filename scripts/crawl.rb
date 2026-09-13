#!/usr/bin/env ruby
# Preserve the public source site for a repeatable migration. Cached downloads
# live in .migration/ and are excluded from both Git and the published site.
require 'nokogiri'
require 'json'
require 'uri'
require 'open3'
require 'fileutils'
require 'set'

ROOT = File.expand_path('..', __dir__)
ORIGIN = 'https://communitygeography.unm.edu'
CACHE = File.join(ROOT, '.migration/source')
FileUtils.mkdir_p(CACHE)

def local_path(url)
  path = URI.decode_www_form_component(URI(url).path)
  path += 'index.html' if path.end_with?('/')
  File.join(CACHE, path.sub(%r{^/}, ''))
end

def canonical(value, source)
  return if value.nil? || value.strip.empty? || value.start_with?('#', 'mailto:', 'tel:', 'javascript:', 'data:')
  # The source CMS exports a placeholder hostname in its public sitemap.
  value = value.sub('http://????.unm.edu', ORIGIN).sub('https://????.unm.edu', ORIGIN)
  uri = URI.join(source, value.strip.gsub(' ', '%20'))
  return unless uri.host == 'communitygeography.unm.edu'
  uri.scheme = 'https'
  uri.fragment = nil
  uri.query = nil
  uri.path = '/index.html' if uri.path == '/'
  uri.to_s
rescue URI::InvalidURIError
  nil
end

def download(url)
  path = local_path(url)
  return [url, path, nil] if File.file?(path)
  FileUtils.mkdir_p(File.dirname(path))
  output, status = Open3.capture2e('curl', '--fail', '--silent', '--show-error', '--location', '--retry', '2', '--max-time', '50', url, '-o', path + '.part')
  if status.success?
    File.rename(path + '.part', path)
    [url, path, nil]
  else
    FileUtils.rm_f(path + '.part')
    [url, path, output.strip]
  end
end

queue = [ORIGIN + '/index.html', ORIGIN + '/sitemap.xml', ORIGIN + '/robots.txt']
seen = Set.new
pages = []
assets = []
failures = []
until queue.empty?
  batch = queue.shift(6).reject { |url| seen.include?(url) }
  batch.each { |url| seen.add(url) }
  batch.map { |url| Thread.new { download(url) } }.map(&:value).each do |url, path, error|
    if error
      failures << {url: url, error: error}
      puts "Unavailable: #{url}"
      next
    end
    if File.extname(path) == '.html'
      doc = Nokogiri::HTML(File.read(path))
      unless doc.at_css('#primary')
        failures << {url: url, error: 'No primary content area found'}
        next
      end
      pages << {url: url, path: path.delete_prefix(ROOT + '/'), title: doc.at_css('#primary h1')&.text&.strip}
      doc.css('a[href]').each do |a|
        target = canonical(a['href'], url)
        queue << target if target
      end
      doc.css('#primary [src], #secondary [src], #tertiary [src], #hero [src], #upper [src], #lower [src]').each do |node|
        target = canonical(node['src'], url)
        queue << target if target
      end
      puts "Page #{pages.size}: #{URI(url).path}"
    elsif File.extname(path) == '.xml'
      Nokogiri::XML(File.read(path)).remove_namespaces!.css('loc').each do |node|
        target = canonical(node.text, url)
        queue << target if target
      end
    elsif File.extname(path) != '.txt'
      assets << {url: url, path: path.delete_prefix(ROOT + '/'), bytes: File.size(path)}
    end
    queue.uniq!
  end
  File.write(File.join(ROOT, '.migration/crawl.json'), JSON.pretty_generate({pages: pages, assets: assets, failures: failures}))
end
puts "Captured #{pages.size} pages and #{assets.size} assets; #{failures.size} unavailable URLs."
