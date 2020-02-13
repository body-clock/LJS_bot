require 'nokogiri'
require 'open-uri'
require 'down'

@ljs_url = 'http://openn.library.upenn.edu/Data/0001/'
@ljs_html = Nokogiri::HTML(open(@ljs_url))

def random_manuscript_xml_url
  skip = ['Name', 'Last modified', 'Size', 'Parent Directory']
  hrefs = @ljs_html.css('div#div_directory a').reject { |node|
    skip.include? node.text
  }.map(&:text)
  @random_manuscript = hrefs.sample.gsub('/', '')
  "#{@ljs_url}#{@random_manuscript}/data/#{@random_manuscript}_TEI.xml"
end

def manuscript_xml(xml_url)
  Nokogiri::XML(open(xml_url)).remove_namespaces!
end

def manuscript_language(xml)
  xml.xpath('//textLang/text()')&.first&.text
end

def valid_xml?(xml)
  page_array = xml.xpath('//surface').select { |node|
    node['n'] =~ /^\d+[rv]/
  }.to_a
  page_array.length >= 4
end

def find_matching_nodes(manuscript_xml)
  page_array = manuscript_xml.xpath('//surface').to_a
  random_page = nil
  until random_page && random_page['n'] =~ /\d+v/
    random_page = page_array.sample
  end
  random_page_index = page_array.index(random_page)
  [page_array[random_page_index], page_array[random_page_index + 1]]
end

def get_urls_from_nokogiri_nodes(nodes)
  first_url = '/' + nodes[0].children[5].attributes['url']
  second_url = '/' + nodes[1].children[5].attributes['url']
  [@ljs_url + @random_manuscript + '/data' + first_url,
   @ljs_url + @random_manuscript + '/data' + second_url]
end

def adjust_image_order(image_url_array)
  image_url_array.reverse
end

def download_images(image_url_array)
  image_url_array.each { |url|
    Down.download(url, destination: '/Users/patrick/work/LJS_bot/images')
  }
end

valid_xml = false
until valid_xml
  url = random_manuscript_xml_url
  xml = manuscript_xml(url)
  valid_xml = valid_xml?(xml)
end

matching_nodes = find_matching_nodes(xml)
url_array = get_urls_from_nokogiri_nodes(matching_nodes)
if manuscript_language(xml) =~ /arabic|hebrew|persian|ottoman turkish|yiddish/i
  url_array.reverse!
  puts 'switched'
else
  url_array
end

puts url
puts manuscript_language(xml)
puts url_array
download_images(url_array)