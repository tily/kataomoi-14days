require 'haml'
require 'aws-sdk'
require 'sinatra'

helpers do
	def q3
		@q3 ||= AWS::SQS.new(
			sqs_endpoint: 'q3-global.herokuapp.com',
			access_key_id: 'dummy',
			secret_access_key: 'dummy',
			use_ssl: false
		)
	end

	def queue
		@queue ||= q3.queues.create('LoveLetter',
			message_retention_period: 14*24*60*60,
			visibility_timeout: 1
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
	message = queue.receive_message
	if message
		@body = message.body
		message.delete
	end
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
		%link{rel:'stylesheet',href:'http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css'}
	%body
		%div.container
			%div.jumbotron
				%h1 14 日間の片想い
				%a{href:'/letters/write'} ラブレターを書く
				%a{href:'/letters'} ラブレターを読む
				= yield
@@ /
%ul
	%li
		%a{href:'/letters/write'} ラブレターを書く
	%li
		%a{href:'/letters'} ラブレターを読む
@@ /letters/write
%form.form{role:'form',method:'POST',action:'/letters'}
	%div.form-group
		%label{for:'body'} 本文
		%textarea.form-control{name:'body',rows:'3'}
	%button{type:'submit',class:'btn btn-default'} 書く
@@ /letters
%div
	%pre= @body || '(手紙は届いていません)'
	%a{href:'/letters'} 次の手紙へ
