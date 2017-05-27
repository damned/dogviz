module Dogviz
  class RenderedSequence
    def initialize(lines)
      @lines = lines
    end

    def output(type_to_file)
      File.write type_to_file.values.first, body
      body
    end

    def body
      @lines.map(&:rstrip).join "\n"
    end    
  end
  
  class WebSequenceDiagramsRenderedSequence < RenderedSequence
  end
  
  class PlantUmlRenderedSequence < RenderedSequence

    def body
      raw_body = super
      ['@startuml', raw_body, '@enduml'].join "\n"
    end
  end
  
end