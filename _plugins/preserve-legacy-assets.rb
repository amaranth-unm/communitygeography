# Jekyll unconditionally skips filenames ending in a dot. This original photo
# URL is linked from a 2021 article, so preserve it after the regular build.
require 'fileutils'
Jekyll::Hooks.register :site, :post_write do |site|
  relative_path = 'news/casa-san-ysidro-by-ramona-m.'
  source = File.join(site.source, relative_path)
  if File.file?(source)
    destination = File.join(site.dest, relative_path)
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp(source, destination)
  end
end
