require 'pry'
require 'mechanize'
require 'fileutils'

require_relative 'exts/peach'
require_relative 'exts/sym_mash'

PREFIX_URL = 'https://web.archive.org/web/20101219015923/'
INDEX_URL  = 'http://rawa.asia/mp3/'
TARGET     = 'mp3'

Dir.mkdir TARGET rescue nil
$http = Mechanize.new

def index_links page, ppath = ''
  page.css('ul li a').each.with_object([]).peach do |a, l|
    path  = a.attr :href
    next if path.start_with? '/web'
    path  = ppath + path

    eurl  = INDEX_URL + path
    next l << eurl unless eurl.end_with?('/')

    epage = $http.get eurl
    puts eurl
    l.concat index_links(epage, path)

  rescue Mechanize::ResponseCodeError
    # usually 404
  end
end

def download url
  puts url
  uri  = URI.parse url
  path = CGI.unescape(uri.path)[1..-1]
  return if File.exists? path

  dir  = CGI.unescape uri.path.split('/')[0..-2].join('/')[1..-1]
  FileUtils.mkdir_p dir

  file = $http.get url
  File.write path, file.body

rescue Mechanize::ResponseCodeError
  # 404
end

# use cached due to web.archive.org blocking
if File.exists? 'files'
  files = File.read('files').split("\n")
  files.map!{ |f| f.gsub PREFIX_URL, '' }
  files.peach do |f|
    download f
  end
else
  page  = $http.get INDEX_URL
  files = index_links page
  File.write 'files', files.join("\n")
end

