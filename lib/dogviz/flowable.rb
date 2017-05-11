require_relative 'process'

module Dogviz
  module Flowable
    def does(action)
      Process.new(self, action)
    end
    
    def receives(requests, &block)
      @requests = self.requests.merge requests
    end
    
    def start_flow(flow)
      @flow = flow
    end
    
    def stop_flow
      @flow = nil
    end

    def method_missing(m, *args, &block)
      if requests.has_key?(m)
        @flow.next_call self, requests[m]
        block.call if block_given?
        @flow.end_call
      end
    end
    
    def requests
      @requests ||= {}
    end
    
    def request_handlers
      @request_handlers ||= {}
    end
    
  end
end