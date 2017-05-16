require_relative 'process'

module Dogviz
  module Flowable
    def does(action)
      Process.new(self, action)
    end
    
    def receives(requests, &block)
      @requests = self.requests.merge requests
    end

    def note(where, what)
      @flow.add_note(self, where, what)
    end
    
    def start_flow(flow)
      @flow = flow
    end
    
    def stop_flow
      @flow = nil
    end

    def method_missing(m, *args, &block)
      if requests.has_key?(m)
        @flow ||= nil

        request_def = requests[m]
        if request_def.is_a?(String)
          label = request_def
          return_label = nil
        else
          label = request_def.keys.first
          return_label = request_def.values.first
        end
        
        @flow.next_call self, label
        block.call if block_given?
        @flow.end_call(return_label)
      else
        raise "this flowable does not know about receiving '#{m}', only know about: #{requests.keys}"
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