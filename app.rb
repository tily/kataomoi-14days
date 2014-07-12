# coding:utf-8
require 'haml'
require 'aws-sdk'
require 'sinatra'

set :haml, :escape_html => true

helpers do
	def sent_at
		@message.sent_timestamp.strftime('%Y 年 %m 月 %d 日')
	end

	def will_disappear_at
		(@message.sent_timestamp + 14*24*60*60).strftime('%Y 年 %m 月 %d 日')
	end

	def q3
		@q3 ||= AWS::SQS.new(
			sqs_endpoint: 'q3-global.herokuapp.com',
			sqs_verify_checksums: false,
			access_key_id: 'dummy',
			secret_access_key: 'dummy',
			use_ssl: false
		)
	end

	def queue
		@queue ||= q3.queues.create('LoveLetter',
			message_retention_period: 14*24*60*60
		)
	end
end

get '/' do
	haml :'/'
end

get '/letters/write' do
	haml :'/letters/write'
end

get '/letters' do
	@visibility_timeout = rand(60)+1
	@message = queue.receive_message(:visibility_timeout => @visibility_timeout)
	haml :'/letters'
end

post '/letters' do
	body = "前略\n\n#{params[:body]}"
	queue.send_message(body)
	redirect '/letters/write'
end

__END__
@@ layout
!!! 5
%html
	%head
		%meta{charset: 'utf-8'}/
		%title 14 日間の片想い
		%link{rel:'stylesheet',href:'http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css'}
	%body
		%div.container
			%div.jumbotron
				%h1 14 日間の片想い
				%a{href:'/'} トップ
				&nbsp;|&nbsp;
				%a{href:'/letters/write'} 手紙をおくる
				&nbsp;|&nbsp;
				%a{href:'/letters'} 手紙をうけとる
				%hr
				!= yield
				%p{style:'text-align:right;width:100%'} 2014 &copy;「14 日間の片想い」製作委員会
@@ /
%ol
	%li 手紙をおくれます
	%li 手紙をうけとれます
	%li 14 日間たつと消えます
@@ /letters/write
%form.form{role:'form',method:'POST',action:'/letters'}
	%div.form-group
		%label{for:'body'} 前略
		%textarea.form-control{name:'body',rows:'3'}
	%button{type:'submit',class:'btn btn-default'} おくる
@@ /letters
%div
	- if @message
		%pre= @message.body
		%ul
			%li= "この手紙は #{@message.approximate_receive_count} 回うけとられました"
			%li= "この手紙は #{sent_at} に送られました、#{will_disappear_at} に消えます"
			%li= "この手紙は #{@visibility_timeout} 秒後にポストへ戻ります"
	- else
		%pre (手紙は届いていません)
	%a{href:'/letters'} 次の手紙へ

