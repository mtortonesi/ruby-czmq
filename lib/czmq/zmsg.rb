module CZMQ
  class ZMessage
    def initialize(zmsg=nil)
      @zmsg = zmsg || LibCZMQ.zmsg_new

      setup_finalizer
    end

    # Need to provide a copy constructor that implements deep copy
    def initialize_copy(orig)
      super
      unless @zmsg.nil?
        @zmsg = LibCZMQ.zmsg_dup(@zmsg)
      end
    end

    def destroy
      if @zmsg
        # Since we explicitly close the zmsg, we have to remove the finalizer.
        remove_finalizer
        LibCZMQ.zmsg_destroy(@zmsg)
        raise 'Error!' unless @zmsg.nil?
      end
    end

    def __send_over(zsocket)
      raise 'Trying to transmit an unitialized ZMessage!' if @zmsg.nil?
      # Since by sending it over a zsocket we explicitly close the zmsg, we
      # have to remove the finalizer.
      remove_finalizer
      rc = LibCZMQ.zmsg_send(@zmsg, zsocket)
      raise 'Error!' unless @zmsg.nil?
      rc
    end

    def size
      LibCZMQ.zmsg_size(@zmsg)
    end

    def content_size
      LibCZMQ.zmsg_content_size(@zmsg)
    end

    def pop(type=:zframe)
      raise 'Trying to pop from an unitialized ZMessage!' if @zmsg.nil?

      case type
      when :zframe
        ZFrame.new(LibCZMQ.zmsg_pop(@zmsg))
      when :string
        LibCZMQ.zmsg_popstr(@zmsg)
      end
    end

    # Push new frame in front of message
    def push(obj)
      raise 'Trying to push in front of an unitialized ZMessage!' if @zmsg.nil?

      if obj.is_a? String
        LibCZMQ.zmsg_pushstr(@zmsg, obj)
      elsif obj.is_a? Array
        LibCZMQ.zmsg_pushmem(@zmsg, obj)
      elsif obj.is_a? ZFrame
        LibCZMQ.zmsg_push(@zmsg, obj.__extract__)
      else
        raise ArgumentError, 'Unknown object type!'
      end
    end

    # Append new frame at the end of message
    def append(obj)
      raise 'Trying to append to an unitialized ZMessage!' if @zmsg.nil?

      if obj.is_a? String
        LibCZMQ.zmsg_addstr(@zmsg, obj)
      elsif obj.is_a? ZFrame
        LibCZMQ.zmsg_append(@zmsg, obj.__extract__)
      else
        raise ArgumentError, 'Unknown object type!'
      end
    end

    alias_method :<<, :append


    private

      # After object destruction, make sure that the corresponding zmsg is
      # destroyed as well.
      #
      # NOTE: We don't care about ensuring, as ffi-rmzq does, that the resource
      # deallocation request comes from the process that allocated it in the first place.
      # In fact, the CZMQ documentation at http://zeromq.org/area:faq explicitly states
      # "It is not safe to share a context or sockets between a parent and its child."
      def setup_finalizer
        ObjectSpace.define_finalizer(self, self.class.close_zmsg(@zmsg))
      end

      def remove_finalizer
        ObjectSpace.undefine_finalizer self
      end

      # Need to make this a class method, or the deallocation won't take place. See:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      def self.close_zmsg(zmsg)
        Proc.new do
          LibCZMQ.zmsg_destroy(zmsg)
          zmsg = nil # Just in case
        end
      end
  end
end
