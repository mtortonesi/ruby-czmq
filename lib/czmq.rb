require 'ruby-czmq-ffi'

CZMQ_LIB_PATH = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(CZMQ_LIB_PATH) unless $LOAD_PATH.include?(CZMQ_LIB_PATH)

require 'ruby-czmq/context'
require 'ruby-czmq/version'
require 'ruby-czmq/zbeacon'
require 'ruby-czmq/zsocket'
