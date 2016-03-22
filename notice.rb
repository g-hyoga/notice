# encoding: utf-8
require '/projects/notice/adapt_ADE.rb'
#require './adapt_ADE.rb'
path = show_adapted_path()
require path + 'pass.rb'
require 'nokogiri'
require 'open-uri'
require 'mail'
require 'validates_email_format_of'
require 'mysql'

#########################################################################################

def gmail(to_adress, from_adress, content)
	Mail.defaults do
		delivery_method :smtp, {
			:address => "smtp.gmail.com",
			:port => 587,
			:domain => 'gmail.com',
			:user_name => 'hyoga0216@gmail.com',
			:password => PASS,
			:authentication => 'plain',
			:enable_starttls_auto => true
		}
	end
	mail = Mail.new do
		from from_adress
		to to_adress
		subject "notice web"
		body content = "from:" + from_adress + "\n\n" + content
	end

	mail.charset = "UTF-8"
	mail.content_transfer_encoding = "8bit"
	mail.deliver

end

def check_mail(mail)
	if mail.include?('@') then
		if ValidatesEmailFormatOf.validate_email_format(mail).nil? then
			return mail
		else
			raise ArgmentError, "this is not enable mail adress"
		end
	else
		raise ArgmentError, "this is not enable mail adress"
	end
end

def insert_url(url, word, adress)
	@client = connect_adapted_mysql()
	stmt = @client.prepare("insert into sites(keyword, url, email, noticed) values(?, ?, ?, false)")
	stmt.execute word, url, adress
end

def delete_url(id)
	@client = connect_adapted_mysql()
	stmt = @client.prepare("delete from sites where id = ?")
	stmt.execute id
end

def update_word(url, next_word, adress)
	@client = connect_adapted_mysql()
	stmt = @client.prepare("update notice set keyword = ? where email = ? and url = ?")
	stmt.execute next_word, adress, url
end

def set_noticed_1(id)
	@client = connect_adapted_mysql()
	stmt = @client.prepare("update sites set noticed = 1 where id = ?")
	stmt.execute id
end

def set_noticed_0(id)
	@client = connect_adapted_mysql()
	stmt = @client.prepare("update sites set noticed = 0 where id = ?")
	stmt.execute id
end

def set_noticed_e(id)
	@client = connect_adapted_mysql()
	stmt = @client.prepare("update sites set noticed = -1 where id = ?")
	stmt.execute id
end

def show_charset(url)
	html_charset = {}
	html = open(url) do |f|
		charset = f.charset
		html_charset[:charset] = charset
		f.read
	end
	html_charset[:html] = html
	return html_charset
end

def add_https(url)
	unless url.include?("http") then
		url = "https://" + url
	end
	return url
end

def remove_https(url)
	if url.include?("http")	&& url.include?("https") then
		#https://
		url = url[8, url.length]
	elsif url.include?("http") then
		url = url[7, url.length]
	end
	return url
end

def notice(id, url, search_word, adress)
	html_charset =  show_charset(url)
	puts html_charset[:charset]
	stop_url = "http://noticeweb.net/config/" + adress

	#doc = Nokogiri::HTML.parse(open(url, "r:Shift_JIS").read)
	doc = Nokogiri::HTML.parse(html_charset[:html], nil, html_charset[:charset])
	doc.css('a, p, h1, h2, h3, span, svg, div').each do |node|
		#if node.text.include?(search_word.force_encoding(html_charset[:charset])) then
		if node.text.include?(search_word.force_encoding("UTF-8")) then
			puts "keyword is discovered!"

			content = "指定したurl(" + url + ")にkeyword(" + search_word + ")が登場したようです。 \n\n通知の変更、削除をしたい場合はこちら -> " + stop_url

			gmail(adress, "notice web", content)
			puts "send mail to " + adress
			#noticed をtrueにする
			set_noticed_1(id)
			break
		end
	end
end

def shorten_string(arg)
	if arg.include?("http") && arg.length >= 50 then
		arg = remove_https(arg)
		arg = arg[0, 49] + "..." 
	elsif arg.length >= 50 then
		arg = arg[0, 49]  + "..."
	end
	return arg
end

