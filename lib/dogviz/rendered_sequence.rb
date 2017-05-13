module Dogviz
  class RenderedSequence
    def initialize(lines)
      @lines = lines
    end

    def output(type_to_file)
      text = @lines.map(&:rstrip).join "\n"
      File.write type_to_file.values.first, text
      text
    end
  end
end