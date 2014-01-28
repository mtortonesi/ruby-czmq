module CZMQ
  class ZPoller
    def initialize(*zsockets)
      @zsockets = zsockets
      @zpoller = @zsockets.map{|zsock| zsock.__peek_zsocket_pointer__ }

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
      zsockptr = LibCZMQ.zpoller_wait(@zpoller, timeout)
      zsockets.select{|zsock| zsock.__peek_zsocket_pointer__ == zsockptr }
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
