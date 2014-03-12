#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'czmq'

begin
  ctx = CZMQ::Context.new
  zsocket = ctx.create_zsocket(CZMQ::REQ)
  zsocket.connect('tcp://localhost:8000')
  puts 'sending string'
  zsocket.send_string('request')
  puts zsocket.receive_string
  zsocket.close
  ctx.close
rescue => e
  STDERR.puts e.backtrace
end
