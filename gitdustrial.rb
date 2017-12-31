require 'watir'
require 'nokogiri'
require 'json'

# variables
src = Watir::Browser.new(:phantomjs)
src.goto "https://git-man-page-generator.lokaltog.net/"
page = Nokogiri::HTML(src.html)
headers = page.css('section#contents h1')

# JSON reader
file = File.read('bands.json')
data_hash = JSON.parse(file)
page.xpath('//@*', '//text()').each do |node|
  node.content = node.content.gsub('git', data_hash[rand(data_hash.length)]["band"])
end

# "options" list generator loop
def option_maker(page)
        option_list = ""
        page.css('#contents #options dt').each do |option|
                option_list = option_list + option.text
                option_list = option_list + "\<br\>"
                option_list = option_list + "&nbsp;&nbsp;&nbsp;" + option.next_element.text
                option_list = option_list + "\<br\>\<br\>"
        end
        return option_list
end

# "see also" list generator loop
def seealso_maker(page)
        seealso_list = ""
        page.css('#contents #see-also li').each do |seealso|
                seealso_list = seealso_list + seealso.text + ", "
                if seealso == page.css('#contents #see-also li').last
                        seealso_list = seealso_list + seealso.text
                end
        end
        return seealso_list
end

# HTML skeleton page
@doc = Nokogiri::HTML::DocumentFragment.parse <<-EOHTML
<html>
<body>
  <h1>NAME</h1>
  <div id="name"></div>
  <h1>SYNOPSIS</h1>
  <div id="synopsis"></div>
  <h1>DESCRIPTION</h1>
  <div id="description">content</div>
  <h1>OPTIONS</h1>
  <div id="options"></div>
  <h1>SEE ALSO</h1>
  <div id="seealso"></div>
</body>
EOHTML

# take elements from page and add them to doc content
new_name = @doc.at_css "div#name"
new_name.content = page.css('#contents #name .command-name').text + " - " + page.css('#contents #name .command-action').text
new_synopsis = @doc.at_css "div#synopsis"
new_synopsis.content = page.css('#contents #synopsis').text
new_desc = @doc.at_css "div#description"
new_desc.content = page.css('#contents #description .command-description').text + "\<br\>\<br\>" + page.css('#contents #description .contents').text
new_options = @doc.at_css "div#options"
new_options.content = option_maker(page)
new_seealso = @doc.at_css "div#seealso"
new_seealso.content = seealso_maker(page)

# print HTML of doc content into index.html
open('/var/www/html/index.html', 'w') { |f|
        f.puts @doc.to_html.gsub("&lt;br&gt;", "<br>").gsub("&amp;nbsp;", "&nbsp;")
}