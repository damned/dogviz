module Dogviz
  class LookupError < StandardError
    def initialize(context, message)
      super "(in context '#{context}') #{message}"
    end
  end
end