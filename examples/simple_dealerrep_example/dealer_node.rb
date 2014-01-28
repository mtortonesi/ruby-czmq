require 'czmq'

ctx = CZMQ::Context.new
if ctx
  zsocket = ctx.create_zsocket(CZMQ::DEALER)
  zsocket.connect('tcp://localhost:7000')
  zsocket.connect('tcp://localhost:8000')
  zsocket.connect('tcp://localhost:9000')

  3.times do
    # in order to talk with REP sockets, we need to prepend each request with
    # a null string frame
    zsocket.send_string('', :more)
    zsocket.send_string('request')

    # rep will be an array of strings, with rep[0] containing an empty string
    # and rep[1] containing the actual reply
    rep = zsocket.receive_strings
    puts rep[1]
  end

  zsocket.close
  ctx.close
else
  STDERR.puts 'Context allocation failed.'
end
