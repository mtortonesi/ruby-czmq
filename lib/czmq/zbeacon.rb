module CZMQ
  class ZBeacon
    def initialize(port, opts={})
      @zbeacon = LibCZMQ.zbeacon_new(port)
      # TODO: check result?

      # Setup no_echo option if requested
      if opts[:no_echo]
        LibCZMQ.zbeacon_no_echo(@zbeacon)
      end

      setup_finalizer
    end

    def hostname
      LibCZMQ.zbeacon_hostname(@zbeacon)
    end

    def set_interval(interval)
      LibCZMQ.zbeacon_set_interval(@zbeacon, interval)
    end

    def publish(data)
      # TODO: transform data into a bytes array
      LibCZMQ.zbeacon_publish(@zbeacon, bytes, size)
    end

    def silence
      LibCZMQ.zbeacon_silence(@zbeacon)
    end

    def subscribe(match=nil)
      if match
        # TODO: transform match data into a bytes array
        LibCZMQ.zbeacon_subscribe(@zbeacon, bytes, size)
      else
        # No match provided. Just pass NULL and 0 to zbeacon_subscribe.
        LibCZMQ.zbeacon_subscribe(@zbeacon, nil, 0)
      end
    end

    def unsubscribe
      LibCZMQ.zbeacon_unsubscribe(@zbeacon)
    end

    def socket
      # TODO: maybe wrap this into a zsocket?
      # NOTE: the value returned by zbeacon_socket should be a ZMQ socket, not
      # a CZMQ zsocket. Check this out.
      LibCZMQ.zbeacon_socket(@zbeacon)
    end

    private

      # After object destruction, make sure that the corresponding zbeacon is
      # destroyed as well.
      #
      # NOTE: We don't care about ensuring, as ffi-rmzq does, that the resource
      # deallocation request comes from the process that allocated it in the first place.
      # In fact, the CZMQ documentation at http://zeromq.org/area:faq explicitly states
      # "It is not safe to share a context or sockets between a parent and its child."
      def setup_finalizer
        ObjectSpace.define_finalizer(self, self.class.close_zbeacon(@zbeacon))
      end

      # Need to make this a class method, or the deallocation won't take place. See:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      def self.close_zbeacon(zbeacon)
        Proc.new do
          zbeacon_ptr = FFI::MemoryPointer.new(:pointer)
          zbeacon_ptr.write_pointer(zbeacon)
          LibCZMQ.zbeacon_destroy(zbeacon_ptr)
          # The following code is not needed, as zbeacon won't be used anymore.
          # zbeacon = zbeacon_ptr.read_pointer
        end
      end
  end
end
