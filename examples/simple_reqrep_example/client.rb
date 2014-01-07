# require 'rubygems'
# require 'bundler/setup'

require 'czmq'

ctx = CZMQ::Context.new
if ctx
  zsocket = ctx.create_zsocket(CZMQ::REQ)
  zsocket.connect('tcp://localhost:8000')
  zsocket.send_string('request')
  puts zsocket.receive_string
  zsocket.close
  ctx.close
else
  STDERR.puts 'Context allocation failed.'
end
