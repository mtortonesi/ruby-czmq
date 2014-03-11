module CZMQ
  class ZLoop
    def initialize(zloop=nil)
      @zloop = zloop || LibCZMQ.zloop_new

      # LibCZMQ.zloop_set_verbose(@zloop, true)

      unless zloop
        setup_finalizer
      end
    end

    def destroy
      if @zloop
        # Since we explicitly close the zloop, we have to remove the finalizer.
        remove_finalizer
        rc = LibCZMQ.zloop_destroy(@zloop)
        raise 'Error!' unless @zloop.nil?
        rc
      end
    end

    def start
      raise 'Trying to start an unitialized ZLoop!' if @zloop.nil?
      LibCZMQ.zloop_start(@zloop)
    end

    def poller(poll_item, func=nil, &block)
      raise 'Trying to add a poller to an unitialized ZLoop!' if @zloop.nil?
      raise ArgumentError, 'You need to provide a block or a proc/lambda!' unless block_given? or func.responds_to :call

      the_proc = block_given? ? block.to_proc : func

      # need to preserve this callback from the garbage collector
      @callback = LibCZMQ.create_zloop_callback(
        lambda do |zloopbuf, zpollitembuf, arg|
          zpollitem = LibCZMQ::ZPollItem.new(zpollitembuf)
          zlp = ZLoop.new(zloopbuf)
          zsk = ZSocket.new(nil, zpollitem[:socket])
          the_proc.call(zlp, zsk)
        end
      )

      LibCZMQ.zloop_poller(@zloop, poll_item, @callback, nil)
    end

    alias_method :add_poller, :poller

    def poller_end(poll_item)
      LibCZMQ.zloop_poller_end(@zloop, poll_item)
      @callback = nil
    end

    alias_method :remove_poller, :poller_end

    def add_timer(delay, times, &block)
      if block
        LibCZMQ.zloop_timer(@zloop, delay, times, block.to_proc, nil)
      end
    end


    private

      # After object destruction, make sure that the corresponding zloop is
      # destroyed as well.
      #
      # NOTE: We don't care about ensuring, as ffi-rmzq does, that the resource
      # deallocation request comes from the process that allocated it in the first place.
      # In fact, the CZMQ documentation at http://zeromq.org/area:faq explicitly states
      # "It is not safe to share a context or sockets between a parent and its child."
      def setup_finalizer
        ObjectSpace.define_finalizer(self, self.class.close_zloop(@zloop))
      end

      def remove_finalizer
        ObjectSpace.undefine_finalizer self
      end

      # Need to make this a class method, or the deallocation won't take place. See:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      def self.close_zloop(zloop)
        Proc.new do
          LibCZMQ.zloop_destroy(zloop)
          zloop = nil # Just in case
        end
      end
  end
end
