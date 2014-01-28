module CZMQ
  class ZFrame
    def initialize(obj=nil)
      if obj.is_a? FFI::Pointer
        @zframe = obj
      else
        @zframe = LibCZMQ.zframe_new(obj)
      end

      setup_finalizer
    end

    # Need to provide a copy constructor that implements deep copy
    def initialize_copy(orig)
      super
      unless @zframe.nil?
        @zframe = LibCZMQ.zframe_dup(@zframe)
      end
    end

    def destroy
      if @zframe
        # Since we explicitly close the zframe, we have to remove the finalizer.
        remove_finalizer
        LibCZMQ.zframe_destroy(@zframe)
        raise 'Error!' unless @zframe.nil?
      end
    end

    def __extract__
      raise 'Trying to extract internal @zframe pointer from an unitialized ZFrame!' if @zframe.nil?

      # Since we explicitly hand over the @zframe pointer, we have to remove the finalizer.
      remove_finalizer

      # Return content of @zframe pointer and reset it to nil
      zframe = @zframe
      @zframe = nil
      zframe
    end


    private

      # After object destruction, make sure that the corresponding zframe is
      # destroyed as well.
      #
      # NOTE: We don't care about ensuring, as ffi-rmzq does, that the resource
      # deallocation request comes from the process that allocated it in the first place.
      # In fact, the CZMQ documentation at http://zeromq.org/area:faq explicitly states
      # "It is not safe to share a context or sockets between a parent and its child."
      def setup_finalizer
        ObjectSpace.define_finalizer(self, self.class.close_zframe(@zframe))
      end

      def remove_finalizer
        ObjectSpace.undefine_finalizer self
      end

      # Need to make this a class method, or the deallocation won't take place. See:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      def self.close_zframe(zframe)
        Proc.new do
          LibCZMQ.zframe_destroy(zframe)
          zframe = nil # Just in case
        end
      end
  end
end
