require 'clockwork'
require './notice.rb'
require './app.rb'
require 'mysql'

include Clockwork

every(10.seconds, 'work')  do
	#urlとsearch_word, mail adressをmysqlからとってくる
	client= Mysql.connect('localhost', 'root', MYSQL_PASS, 'notice')
	client.query("select noticed from sites").each do |noticed|
		if noticed == false then
			client.query("select url, keyword, email from sites").each do |url, word, mail_adress|
				puts url, word, mail_adress
				#notice(url, word, mail_adress)
				#noticed をtrueにする
			end
		end
	end
end






