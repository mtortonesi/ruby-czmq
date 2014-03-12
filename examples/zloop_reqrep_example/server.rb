#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'czmq'

ctx = CZMQ::Context.new
abort 'Context allocation failed.' unless ctx

zsocket = ctx.create_zsocket(CZMQ::REP)

begin
  zsocket.bind('tcp://*:8000')
  zloop = CZMQ::ZLoop.new
  pi = zsocket.to_pollitem
  zloop.poller(pi) do |zlp,socket|
    str = socket.receive_string
    puts "Received on REQ/REP ZSocket: #{str}"; STDOUT.flush
    socket.send_string(str.reverse)
  end
  zloop.start
rescue => e
  STDERR.puts e.inspect
  STDERR.puts e.backtrace
end

zsocket.close
ctx.close
