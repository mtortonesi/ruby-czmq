module CZMQ
  class ZPoller

    def initialize(zctx, *zobjs)
      raise ArgumentError, 'Must provide at least one ZSocket!' if zobjs.empty?

      # # Need to save context for ZSocket operations
      # @zctx = zctx
      @zsockets = zobjs

      # We need to setup the ZPoller from zsocket pointers, not ZSocket objects
      zsocks = zobjs.map{|zo| zo.__get_zsocket_pointer__ }

      # Create zpoller by calling zpoller_new
      first_arg = zsocks.shift
      if zsocks.empty?
        # We just need to pass a single argument
        @zpoller = LibCZMQ.zpoller_new(first_arg)
      else
        # We also need to pass additional arguments, using the horrible varargs interface
        other_args = ([ :pointer ] * zsocks.size).zip(zsocks).flatten
        @zpoller = LibCZMQ.zpoller_new(first_arg, *other_args)
      end

      setup_finalizer
    end


    def destroy
      if @zpoller
        # Since we explicitly close the zpoller, we have to remove the finalizer.
        remove_finalizer
        LibCZMQ.zpoller_destroy(@zpoller)
        raise 'Error!' unless @zpoller.nil?
      end
    end


    def wait(timeout)
      raise "Can't wait on an uninitialized ZPoller!" unless @zpoller
      # TODO: should we return a newly created ZSocket or an existing one?
      zsockptr = LibCZMQ.zpoller_wait(@zpoller, timeout)
      yield zsockets.select{|zsock| zsock.__get_zsocket_pointer__ == zsockptr }
    end


    def expired?
      raise "Can't check if an uninitialized ZPoller is expired!" unless @zpoller
      LibCZMQ.zpoller_expired(@zpoller)
    end


    def terminated?
      raise "Can't check if an uninitialized ZPoller is terminated!" unless @zpoller
      LibCZMQ.zpoller_terminated(@zpoller)
    end


    private

      # After object destruction, make sure that the corresponding zpoller is
      # destroyed as well.
      #
      # NOTE: We don't care about ensuring, as ffi-rmzq does, that the resource
      # deallocation request comes from the process that allocated it in the first place.
      # In fact, the CZMQ documentation at http://zeromq.org/area:faq explicitly states
      # "It is not safe to share a context or sockets between a parent and its child."
      def setup_finalizer
        ObjectSpace.define_finalizer(self, self.class.close_zpoller(@zpoller))
      end

      def remove_finalizer
        ObjectSpace.undefine_finalizer self
      end

      # Need to make this a class method, or the deallocation won't take place. See:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      def self.close_zpoller(zpoller)
        Proc.new do
          LibCZMQ.zpoller_destroy(zpoller)
          zpoller = nil # Just in case
        end
      end
  end
end
