module CZMQ
  class ZBeacon
    def initialize(port, opts={})
      @zbeacon = LibCZMQ.zbeacon_new(port)

      # zbeacon_new returns NULL in case of failure
      raise "Could not create ZBeacon" if @zbeacon.null?

      # Setup no_echo option if requested
      if opts[:no_echo]
        LibCZMQ.zbeacon_no_echo(@zbeacon)
      end

      # Setup the finalizer to free the memory allocated by the CZMQ library
      setup_finalizer
    end

    def close
      if @zbeacon
        # Since we explicitly close the ZBeacon, we have to remove the finalizer.
        remove_finalizer

        # Destroy the ZBeacon
        LibCZMQ.zbeacon_destroy(@zbeacon)

        # Unset @zbeacon
        @zbeacon = nil
      end
    end

    def hostname
      raise "Can't get the hostname of a closed ZBeacon!" unless @zbeacon
      LibCZMQ.zbeacon_hostname(@zbeacon)
    end

    def set_interval(interval)
      raise "Can't set the advertisement interval of a closed ZBeacon!" unless @zbeacon
      LibCZMQ.zbeacon_set_interval(@zbeacon, interval)
    end

    def publish(data)
      raise "Can't set the advertisement interval of a closed ZBeacon!" unless @zbeacon

      # Transform data into a bytes array
      bytes = to_bytearray(data)

      LibCZMQ.zbeacon_publish(@zbeacon, bytes, bytes.size)
    end

    def silence
      raise "Can't silenc a closed ZBeacon!" unless @zbeacon
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

    def zsocket
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

      def remove_finalizer
        ObjectSpace.undefine_finalizer self
      end

      # Need to make this a class method, or the deallocation won't take place. See:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      def self.close_zbeacon(zbeacon)
        Proc.new do
          LibCZMQ.zbeacon_destroy(zbeacon)
          zbeacon = nil # Just in case
        end
      end

      def to_bytearray
        bytes = nil
        if data.is_a? String
          # String to byte array conversion using the default UTF-8 encoding
          bytes = data.encode("UTF-8").bytes.to_a
        elsif data.respond_to? :to_a and !data.is_a? Array
          bytes = data
        else
          raise "Don't know how to deal with data" unless data.is_a? Array
          bytes = data
        end
      end
  end
end
