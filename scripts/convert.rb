#!/usr/bin/env ruby
# Converts cached public pages to editable Jekyll Markdown, preserving URLs.
# Run only for a fresh import: this overwrites migrated content and data files.
require 'nokogiri'
require 'json'
require 'yaml'
require 'uri'
require 'open3'
require 'fileutils'
require 'time'
ROOT = File.expand_path('..', __dir__)
ORIGIN = 'https://communitygeography.unm.edu'
manifest = JSON.parse(File.read(File.join(ROOT, '.migration/crawl.json')))
available = (manifest['pages'] + manifest['assets']).map { |item| URI(item['url']).path }

def resolve(value, source)
  return value if value.nil? || value.strip.empty? || value.start_with?('#', 'mailto:', 'tel:', 'data:')
  uri = URI.join(source, value.strip.gsub(' ', '%20'))
  uri.scheme = 'https' if uri.host == 'communitygeography.unm.edu'
  if uri.host == 'communitygeography.unm.edu'
    uri.path = uri.path.sub('/%20news/', '/news/')
    uri.path = '/about/our-team.html' if uri.path == '/about/staff.html'
    uri.path = '/about/contact-us.html' if uri.path == '/about/contact.html'
    return 'https://canvas.unm.edu/courses/39553/pages' if uri.path == '/funding/canvas.unm.edu/courses/39553/pages'
    uri.fragment = nil if %w[gradanchor facultyanchor].include?(uri.fragment)
  end
  uri.to_s
rescue URI::InvalidURIError
  value
end

def clean(node)
  node.css('p').each do |child|
    child.name = 'h2' if ['Associate Director', 'Graduate Assistant'].include?(child.text.strip)
  end
  node.css('h3').each { |child| child.name = 'h2' if child.text.tr("\u00a0", ' ').strip == 'Director' }
  node.css('script, style').remove
  node.css('p').reverse_each do |child|
    child.remove if child.text.gsub(/[[:space:]\u00a0]/, '').empty? && child.css('img, iframe, video, audio, object').empty? && !child['id'] && !child['name']
  end
  node.css('[style], [face], [color], [size]').each do |child|
    %w[style face color size].each { |attr| child.remove_attribute(attr) }
  end
  node.css('span').reverse_each { |child| child.replace(child.children) unless child['id'] }
  # Empty CMS formatting can become stray Markdown emphasis or empty links.
  # Keep whitespace and line breaks so adjacent words remain separate.
  node.css('a, strong, b, em, i').reverse_each do |child|
    if child.text.gsub(/[[:space:]\u00a0]/, '').empty? && child.css('img, iframe, video, audio, object').empty? && !child['id'] && !child['name']
      child.replace(child.children)
    end
  end
  # CMS layout wrappers are obsolete; keeping them would make Markdown inside
  # their raw HTML blocks render as literal punctuation under Kramdown.
  node.css('div').reverse_each do |child|
    child.add_previous_sibling("\n")
    child.add_next_sibling("\n")
    if child['id']
      anchor = Nokogiri::XML::Node.new('a', node.document)
      anchor['id'] = child['id']
      child.add_previous_sibling(anchor)
    end
    child.replace(child.children)
  end
  node.css('br').each { |br| br.remove if br.parent&.name&.match?(/^h[1-6]$/) }
  node.css('img').each do |img|
    img['alt'] = node.at_css('h1')&.text&.strip || 'Community Geography project image' if img['alt'].to_s.empty?
    img['loading'] ||= 'lazy'
    img['decoding'] = 'async'
  end
  node.css('iframe').each { |frame| frame['title'] ||= 'Embedded community geography resource'; frame['loading'] = 'lazy' }
  node
end

def markdown(node, source, available)
  tokens = {}
  clean(node)
  node.css('[href], [src], [poster], [data]').each do |child|
    %w[href src poster data].each do |attr|
      next unless child[attr]
      value = resolve(child[attr], source)
      if child.name == 'img' && value == ORIGIN + '/_internal/content/geog2115_sp22graphic_betterthantexas.png'
        child.remove
        next
      end
      begin
        uri = URI(value)
        if uri.host == 'communitygeography.unm.edu'
          path = uri.path == '/' ? '/index.html' : uri.path
          if available.include?(path)
            target = path + (uri.query ? '?' + uri.query : '') + (uri.fragment ? '#' + uri.fragment : '')
            token = "MIGRATIONURL#{tokens.size}TOKEN"
            tokens[token] = "{{ #{target.to_json} | relative_url }}"
            value = token
          end
        end
      rescue URI::InvalidURIError
      end
      child[attr] = value
    end
  end
  output, error, status = Open3.capture3('pandoc', '--from=html', '--to=gfm', '--wrap=none', stdin_data: node.inner_html)
  raise error unless status.success?
  tokens.each { |token, value| output.gsub!(token, value.gsub('"', "'")) }
  output.gsub(/\n{3,}/, "\n\n").strip + "\n"
end

home_doc = Nokogiri::HTML(File.read(File.join(ROOT, '.migration/source/index.html')))
nav = home_doc.css('#horz-nav > ul > li').map do |li|
  a = li.at_css('a')
  item = {'title' => a.text.gsub(/[[:space:]\u00a0]+/, ' ').strip, 'url' => URI(resolve(a['href'], ORIGIN + '/')).path}
  children = li.css('ul a').map { |link| {'title'=>link.text.strip, 'url'=> URI(resolve(link['href'], ORIGIN + '/')).path} }
  item['items'] = children unless children.empty?
  item
end
news_nav = nav.find { |item| item['title'] == 'News' }
news_nav['items'].reverse!
File.write(File.join(ROOT, '_data/nav-top.yml'), nav.to_yaml)

manifest['assets'].each do |item|
  path = URI.decode_www_form_component(URI(item['url']).path).sub(%r{^/}, '')
  destination = File.join(ROOT, path)
  FileUtils.mkdir_p(File.dirname(destination))
  original = File.join(ROOT, item['path'])
  FileUtils.cp(original, destination) unless File.file?(destination) && FileUtils.compare_file(original, destination)
end

records = manifest['pages'].map do |item|
  doc = Nokogiri::HTML(File.read(File.join(ROOT, item['path'])))
  main = doc.at_css('#primary').dup
  path = URI(item['url']).path
  title = main.at_css('h1')&.text&.strip
  title = doc.at_css('title').text.split('|').first.strip if title.nil? || title.empty?
  section = nav.find { |n| n['url'].split('/')[1] == path.split('/')[1] }
  front = {'title' => title, 'permalink' => path, 'source_url' => item['url']}
  if path == '/index.html'
    front['home'] = true
    front['layout'] = 'home-unm'
    main.at_css('img')['alt'] = 'Cottonwoods in the Rio Grande bosque. Photograph by Maria Lane.'
    main.at_css('img')['loading'] = 'eager'
    main.css('a').each do |a|
      a.content = 'Learn more about the Center →' if a.at_css('img') && a['href'].include?('about/index.html')
    end
  end
  if section && section['url'] != path
    front.merge!('section' => section['title'], 'section_url' => section['url'])
  end
  description = doc.at_css('meta[name="description"]')&.[]('content')&.strip
  front['summary'] = description unless description.nil? || description.empty?
  if main.css('.project-box').any?
    key = path.include?('past-projects') ? 'past-projects' : 'projects'
    projects = main.css('.project-box').map do |card|
      a = card.at_css('a')
      img = card.at_css('img')
      {'title'=>card.at_css('h3').text.gsub(/[[:space:]\u00a0]+/,' ').strip,
       'url'=>URI(resolve(a['href'], item['url'])).path,
       'image'=>URI(resolve(img['src'], item['url'])).path,
       'alt'=>img['alt'], 'dates'=>card.css('.project-box-date').map{|p| p.text.gsub(/[[:space:]\u00a0]+/,' ').strip}}
    end
    File.write(File.join(ROOT, "_data/#{key}.yml"), projects.to_yaml)
    content = "# #{title}\n\n{% include community/projects.html collection='#{key}' %}\n"
  else
    content = markdown(main, item['url'], available)
    # The secondary column is repeated navigation. Other editorial sidebar
    # content is retained, except the repeated social block in the site footer.
    doc.css('#secondary, #tertiary').each do |aside|
      aside = aside.dup
      aside.css('nav, .sidebar-nav-wrapper').remove
      aside.css('h2, h5').each { |n| n.remove if n.text.match?(/Follow us|@NMcommunitygeog/) }
      extra = markdown(aside, item['url'], available)
      if path == '/index.html'
        File.write(File.join(ROOT, '_includes/community/home-news.md'), extra)
      else
        content += "\n---\n\n#{extra}" unless extra.strip.empty?
      end
    end
  end
  target = path.sub(/\.html$/, '.md').sub(%r{^/}, '')
  FileUtils.mkdir_p(File.dirname(File.join(ROOT, target)))
  File.write(File.join(ROOT, target), front.to_yaml + "---\n\n" + content)
  {source: item['url'], file: target, permalink: path, title: title}
end
FileUtils.mkdir_p(File.join(ROOT, 'migration'))
File.write(File.join(ROOT, 'migration/manifest.json'), JSON.pretty_generate({captured_at: Time.now.utc.iso8601, pages: records, assets: manifest['assets'].map { |a| a.reject { |k,_| k == 'path' } }, unavailable: manifest['failures']}))
puts "Converted #{records.size} pages and copied #{manifest['assets'].size} assets."
