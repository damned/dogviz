module Dogviz
  class Process
    def initialize(processor, description)
      @processor = processor
      @description = description
    end

    def name
      @processor.name
    end

    def description
      @description
    end

    attr_reader :processor
  end
end