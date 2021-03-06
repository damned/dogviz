module Dogviz
  class RenderedSequence
    def initialize(lines, message_handler)
      @lines = lines
      @message_handler = message_handler
    end

    def output(type_to_file, executor = nil)
      File.write type_to_file.values.first, body
      output_message "Created sequence definition: #{type_to_file}"
      body
    end

    def body
      @lines.map(&:rstrip).join "\n"
    end    

    def output_message(message)
      @message_handler.output_message message
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


  class Executor
    def execute(cmd)
      system cmd
    end
  end
  
  class PngRenderedSequence < PlantUmlRenderedSequence
    def output(type_to_file, executor = nil)
      image_type, image_filename = type_to_file.first
      plantuml_definition_filename = without_extension(image_filename) + '.plantuml'

      definition = super plantuml: plantuml_definition_filename

      executor = Executor.new if executor.nil?
      executor.execute(plantuml_cmd image_type, plantuml_definition_filename)

      output_message "Created sequence image: #{{image_type => image_filename}}"

      definition
    end

    private

    def plantuml_cmd(image_type, plantuml_definition_filename)
      "plantuml -t#{image_type} #{plantuml_definition_filename}"   
    end
    
    def without_extension(filename)
      filename.gsub(/\.[a-zA-Z]*$/, '')
    end
  end
  
end