# require 'rubygems'
# require 'bundler/setup'

require 'czmq'

ctx = CZMQ::Context.new
if ctx
  puts CZMQ::REP
  zsocket = ctx.create_zsocket(CZMQ::REP)
  puts zsocket.bind('tcp://*:8000')
  puts zsocket.receive_string
  zsocket.send_string('response')
  zsocket.close
  ctx.close
else
  STDERR.puts 'Context allocation failed.'
end
