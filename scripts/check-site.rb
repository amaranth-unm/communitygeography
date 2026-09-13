#!/usr/bin/env ruby
# Check the generated site, including project-prefix routing and search JSON.
require 'nokogiri'
require 'json'
require 'yaml'
require 'uri'
require 'cgi'
root = File.expand_path(ARGV.fetch(0, '_site'))
config = YAML.load_file('_config.yml')
config.merge!(YAML.load_file('_config.ci.yml')) if File.file?('_config.ci.yml')
base = config.fetch('baseurl', '')
errors = []
documents = {}
Dir.glob(File.join(root, '**/*.html')).each { |file| documents[file] = Nokogiri::HTML(File.read(file)) }
documents.each do |file, doc|
  errors << "#{file}: missing main landmark" unless doc.at_css('main#main')
  doc.css('a[href], img[src], script[src], link[href], iframe[src]').each do |node|
    value = node['href'] || node['src']
    next if value.nil? || value.empty? || value.match?(%r{^(https?:|//|mailto:|tel:|data:)})
    path, fragment = value.split('#', 2)
    path = CGI.unescape(path.to_s.split('?',2).first.to_s)
    target = if path.empty?
      file
    elsif path.start_with?('/')
      if !base.empty? && path != base && !path.start_with?(base + '/')
        errors << "#{file.delete_prefix(root)}: missing project prefix: #{value}"
      end
      File.join(root, path.delete_prefix(base).sub(%r{^/}, ''))
    else
      File.expand_path(path, File.dirname(file))
    end
    target = File.join(target, 'index.html') if File.directory?(target)
    if !File.file?(target)
      errors << "#{file.delete_prefix(root)}: missing target #{value}"
    elsif fragment && !fragment.empty? && documents[target]
      ids = documents[target].css('[id], a[name]').flat_map { |n| [n['id'], n['name']] }.compact
      errors << "#{file.delete_prefix(root)}: missing fragment #{value}" unless ids.include?(CGI.unescape(fragment))
    end
  end
  doc.css('img:not([alt])').each { |img| errors << "#{file}: missing image alternative: #{img['src']}" }
end
begin
  index = JSON.parse(File.read(File.join(root, 'assets/search-index.json')))
  errors << 'Search index is empty' if index.empty?
rescue JSON::ParserError => e
  errors << "Invalid search index: #{e.message}"
end
if File.file?('migration/manifest.json')
  JSON.parse(File.read('migration/manifest.json'))['pages'].each do |page|
    errors << "Missing migrated page: #{page['permalink']}" unless File.file?(File.join(root, page['permalink'].sub(%r{^/}, '')))
  end
end
abort errors.uniq.join("\n") unless errors.empty?
puts "Checked #{documents.size} pages: internal links, images, fragments, landmarks, preserved URLs, and search JSON passed."
