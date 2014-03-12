#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'czmq'

zloop = CZMQ::ZLoop.new
zloop.add_timer(2_000, 2) do |*args|
  puts "#{Time.now} called block inside first callback"
  puts "args = #{args.inspect}"
end
zloop.add_timer(10_000, 1) do |*args|
  puts "#{Time.now} called block inside second callback"
  puts "args = #{args.inspect}"
end
zloop.start
