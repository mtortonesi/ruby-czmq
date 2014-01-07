require 'ffi'

module CZMQ
  class Context

    def initialize(opts = {})
      # TODO: check this code
      _DEFAULT_OPTS = { io_threads: 1, linger: 0 }
      opts = _DEFAULT_OPTS.merge(opts)

      @zctx = LibCZMQ.zctx_new
      # TODO: check that this is not null

      # Setup multiple I/O threads if requested
      if opts[:io_threads].is_a? Numeric and opts[:io_threads] > 1
        LibCZMQ.zctx_set_iothreads(@zctx, opts[:io_threads])
      end

      setup_finalizer
    end

    def close
      if @zctx
        # Since we explicitly close the zctx, we have to remove the finalizer.
        remove_finalizer
        LibCZMQ.zctx_destroy(@zctx)
        @zctx = nil
      end
    end

    def create_zsocket(type, opts={})
      ZSocket.new(@zctx, type, opts)
    end

    def create_zbeacon(port, opts={})
      ZBeacon.new(@zctx, port, opts)
    end

    # TODO: consider whether to provide the set_iothreads and set_linger methods as well.


    private

      # After object destruction, make sure that the corresponding zctx is
      # destroyed as well.
      #
      # NOTE: We don't care about ensuring, as ffi-rmzq does, that the resource
      # deallocation request comes from the process that allocated it in the first place.
      # In fact, the CZMQ documentation at http://zeromq.org/area:faq explicitly states
      # "It is not safe to share a context or sockets between a parent and its child."
      def setup_finalizer
        ObjectSpace.define_finalizer(self, self.class.close_zctx(@zctx))
      end

      def remove_finalizer
        ObjectSpace.undefine_finalizer self
      end

      # Need to make this a class method, or the deallocation won't take place. See:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      def self.close_zctx(zctx)
        Proc.new do
          LibCZMQ.zctx_destroy(zctx)
          zctx = nil # Just in case
        end
      end
  end
end
