require_relative 'container'
module Dogviz
  class LogicalContainer < Container
    def initialize(parent, name, options)
      super parent, name, options.merge(bounded: false)
    end
  end
end