module Dogviz
  module Common
    def create_id(name, parent)
      parts = []
      parts << parent.id if parent.respond_to? :id
      parts += name.split(/\s/)
      parts.join '_'
    end

    def root
      ancestors.last
    end

    def ancestors
      ancestors = [parent]
      loop do
        break unless ancestors.last.respond_to?(:parent)
        ancestors << ancestors.last.parent
      end
      ancestors
    end

    def info(fields)
      @info.merge! fields
      setup_render_attributes(label: label_with_info)
      self
    end

    def doclink(url)
      setup_render_attributes(URL: url)
    end

    def label_with_info
      lines = [name]
      @info.each { |k, v|
        lines << "#{k}: #{v}"
      }
      lines.join "\n"
    end

    def setup_render_attributes(attributes)
      @attributes ||= {}
      @attributes.merge!(attributes)
    end

    def rollup?
      @rollup
    end

    def rollup!
      @rollup = true
      self
    end

    def skip!
      @skip = true
      self
    end

    def skip?
      @skip
    end

    def in_skip?
      skip? || under_skip?
    end

    def under_skip?
      ancestors.any?(&:skip?)
    end

    def under_rollup?
      ancestors.any?(&:rollup?)
    end

    def in_rollup?
      rollup? || under_rollup?
    end

    def on_top_rollup?
      rollup? && !under_rollup?
    end

    def inherited_render_options
      inherited = {}
      inherited[:fontname] = parent.render_options[:fontname] if parent.render_options.include?(:fontname)
      inherited
    end
  end
end