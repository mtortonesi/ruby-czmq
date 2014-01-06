require 'ffi'
require 'ruby-cmzq-ffi'


module CZMQ
  class ZSocket

    def initialize(zctx, type, opts = {})
      @zsocket = LibCZMQ.zsocket_new(zctx, type)
      # TODO: check that zsocket is not null?

      setup_finalizer
    end

    def close
      if @zsocket
        # Since we explicitly close the zsocket, we have to remove the finalizer.
        remove_finalizer
        LibZMQ.zsocket_destroy(@zsocket)
        @zsocket = nil
      end
    end

    def bind(address, opts={})
      raise "Can't bind a closed ZSocket!" unless @zsocket
      # TODO: pass opts to zsocket_bind using varargs
      LibCZMQ.zsocket_bind(@zsocket, address)
    end

    def unbind(address, opts={})
      raise "Can't unbind a closed ZSocket!" unless @zsocket
      # TODO: pass opts to zsocket_unbind using varargs
      LibCZMQ.zsocket_unbind(@zsocket, address)
    end

    def connect(address, opts={})
      raise "Can't connect a closed ZSocket!" unless @zsocket
      # TODO: pass opts to zsocket_connect using varargs
      LibCZMQ.zsocket_connect(@zsocket, address)
    end

    def disconnect(address, opts={})
      raise "Can't disconnect a closed ZSocket!" unless @zsocket
      # TODO: pass opts to zsocket_disconnect using varargs
      LibCZMQ.zsocket_disconnect(@zsocket, address)
    end

    def poll(msecs)
      raise "Can't poll a closed ZSocket!" unless @zsocket
      LibCZMQ.zsocket_poll(@zsocket, msecs)
    end

    def type
      raise "Can't read type of a closed ZSocket!" unless @zsocket
      type_ptr = LibCZMQ.zsocket_type_str(@zsocket)
      # TODO: check if we need to return a duped string
      type_ptr.null? ? nil : type_ptr.read_string()
    end

    def receive_string(*opts)
      if opts.include? :no_wait
        str_ptr = LibCZMQ.zstr_recv_nowait(@socket)
        # No need to raise exception if zstr_recv_nowait returns NULL.
        extract_str(str_ptr)
      elsif opts.include? :multipart
        # TODO: call zstr_recvx
      else
        str_ptr = LibCZMQ.zstr_recv(@socket)
        raise "Can't read string from ZSocket" if str_ptr.null?
        extract_str(str_ptr)
      end
    end

    def send_string(str, *opts)
      if opts.include? :more
        LibCZMQ.zstr_sendm(@socket, str)
        # TODO: check the code returned by zstr_sendm?
      elsif opts.include? :multipart
        # TODO: call zstr_sendx
      else
        LibCZMQ.zstr_send(@socket, str)
        # TODO: check the code returned by zstr_send?
      end
    end

    # TODO: implement this
    # def sendmem
    #   raise CZMQException, "Can't sendmem to a closed ZSocket!" unless @zsocket
    # end

    private

      # After object destruction, make sure that the corresponding zsocket is
      # destroyed as well.
      #
      # NOTE: We don't care about ensuring, as ffi-rmzq does, that the resource
      # deallocation request comes from the process that allocated it in the first place.
      # In fact, the CZMQ documentation at http://zeromq.org/area:faq explicitly states
      # "It is not safe to share a context or sockets between a parent and its child."
      def setup_finalizer
        ObjectSpace.define_finalizer(self, self.class.close_zsocket(@zsocket))
      end

      def remove_finalizer
        ObjectSpace.undefine_finalizer self
      end

      # Need to make this a class method, or the deallocation won't take place. See:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      def self.close_zsocket(zsocket)
        Proc.new do
          zsocket_ptr = FFI::MemoryPointer.new(:pointer)
          zsocket_ptr.write_pointer(zsocket)
          LibCZMQ.zsocket_destroy(zsocket_ptr)
          # The following code is not needed, as zsocket won't be used anymore.
          # zsocket = zsocket_ptr.read_pointer
        end
      end

      def extract_str(ffi_str_pointer)
        # Make sure we don't try to extract a string from a NULL pointer.
        return nil if ffi_str_pointer.null? || ffi_str_pointer.nil?

        # Read the string pointed by ffi_str_pointer.
        str = ffi_str_pointer.read_pointer.read_string

        # The read_string method (actually, the str_new C function nested
        # inside it) makes a deep copy, so we can safely free ffi_str_pointer.
        ffi_str_pointer.free

        # Return the string we extracted from ffi_str_pointer.
        str
      end
  end
end
