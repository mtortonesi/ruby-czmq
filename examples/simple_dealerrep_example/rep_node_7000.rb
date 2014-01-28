require 'czmq'

ctx = CZMQ::Context.new
if ctx
  zsocket = ctx.create_zsocket(CZMQ::REP)
  zsocket.bind('tcp://*:7000')

  puts zsocket.receive_string
  zsocket.send_string('reply')

  zsocket.close
  ctx.close
else
  STDERR.puts 'Context allocation failed.'
end
