require_relative 'process'

module Dogviz
  module Flowable
    def does(action)
      Process.new(self, action)
    end
  end
end