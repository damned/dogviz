require_relative 'process'
require_relative 'rendered_sequence'

module Dogviz
  class SequenceRenderer
    attr_reader :lines

    def initialize(title)
      @lines = []
      @indents = 0
      @rendered_class = RenderedSequence
      add_title title
    end

    def render_edge(from, other, options)
      detail = options[:label]
      receiver_label = other.name
      sender_label = from.name
      annotations = nil
      if other.is_a?(Process)
        annotations = extract_annotations(detail, sender_label, receiver_label, other.description)
        receiver_label = process_start_label(receiver_label)
      elsif from.is_a?(Process)
        receiver_label = process_end_label(receiver_label)
      end
      line = "#{escape sender_label} -> #{escape receiver_label}: #{escape detail}"
      line = [ line, annotations ].join("\n") unless annotations.nil?
      add_line line
    end

    def start_combination(operator, guard)
      add_line "#{operator} #{escape guard}"
      @indents += 1
    end
    
    def end_combination
      @indents -= 1
      add_line 'end'
    end

    def note(from, where, what)
      add_line "note #{where} of #{escape from.name}"
      @indents += 1
      add_line what
      @indents -= 1
      add_line "end note"
    end

    def rendered
      @rendered_class.new lines
    end

    private

    def add_line(line)
      lines << ('  ' * @indents + line)
    end

    def add_title(title)
      add_line "title #{escape title}"
    end

    def process_start_label(receiver_label)
      "+#{receiver_label}"
    end

    def process_end_label(receiver_label)
      "-#{receiver_label}"
    end

    def extract_annotations(detail, sender, receiver, process_description)
      [ "note right of #{escape receiver}",
        "  #{escape process_description}",
        'end note' ].join("\n")
    end

    def escape(s)
      if (/\s/).match(s)
        "\"#{s}\""
      else
         s
      end
    end
    
  end

  class WebSequenceDiagramsSequenceRenderer < SequenceRenderer
    def initialize title
      super title
      @rendered_class = WebSequenceDiagramsRenderedSequence
    end    
  end
  
  class PlantUmlSequenceRenderer < SequenceRenderer
    def initialize title
      super title
      @rendered_class = PlantUmlRenderedSequence
    end    
  end

  class PngSequenceRenderer < SequenceRenderer
    def initialize title
      super title
      @rendered_class = PngRenderedSequence
    end    
  end
  
  
end