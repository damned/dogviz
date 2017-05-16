require_relative 'process'
require_relative 'rendered_sequence'

module Dogviz
  class SequenceRenderer
    attr_reader :lines

    def initialize(title)
      @lines = []
      @indents = 0
      add_title title
    end

    def render_edge(from, other, options)
      detail = options[:label]
      receiver_label = other.name
      sender_label = from.name
      if other.is_a?(Process)
        detail = process_annotations(detail, sender_label, receiver_label, other.description)
        receiver_label = process_start_label(receiver_label)
      elsif from.is_a?(Process)
        receiver_label = process_end_label(receiver_label)
      end
      add_line "#{sender_label} -> #{receiver_label}: #{detail}"
    end

    def start_combination(operator, guard)
      add_line "#{operator} #{guard}"
      @indents += 1
    end
    
    def end_combination
      @indents -= 1
      add_line 'end'
    end

    def note(from, where, what)
      add_line "note #{where} of #{from.name}"
      @indents += 1
      add_line what
      @indents -= 1
      add_line "end note"
    end

    def rendered
      RenderedSequence.new lines
    end

    private

    def add_line(line)
      lines << ('  ' * @indents + line)
    end

    def add_title(title)
      add_line "title #{title}"
    end

    def process_start_label(receiver_label)
      "+#{receiver_label}"
    end

    def process_end_label(receiver_label)
      "-#{receiver_label}"
    end

    def process_annotations(detail, sender, receiver, process_description)
      detail = [detail,
                "note right of #{receiver}",
                "  #{process_description}",
                'end note'].join("\n")
    end
  end
end