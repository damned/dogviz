require_relative 'common'
require_relative 'nominator'
require_relative 'flowable'
require_relative 'colorizer'

module Dogviz
  class Thing
    include Common
    include Nominator
    include Flowable
    attr_reader :parent
    attr_reader :name, :id, :pointers, :edge_heads

    @@colorizer = Colorizer.new

    def initialize(parent, name, options = {})
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      @pointers = []
      @rollup = false
      @skip = false
      @info = {}
      @edge_heads = []

      rollup! if options[:rollup]
      options.delete(:rollup)

      @render_options = options
      setup_render_attributes({label: name}.merge inherited_render_options)

      parent.register name, self
    end

    def points_to_all(*others)
      others.each { |other|
        points_to other
      }
    end

    def points_to(other, options = {})
      setup_render_edge(other, options)
      other
    end

    alias_method :to, :points_to
    alias_method :to_all, :points_to_all

    def render(renderer)
      do_render_node(renderer) unless in_rollup? || in_skip?
    end

    def render_edges(renderer)
      pointers.each { |p|
        render_pointer p, renderer
      }
    end

    private

    def do_render_node(renderer)
      renderer.render_node(parent, id, @render_options.merge(@attributes), self)
    end

    def setup_render_edge(other, options)
      fontsize = 14
      fontsize += options[:stroke] if options.has_key?(:stroke)
      pointers << {
          other: other,
          options: {
              xlabel: options[:name],
              style: options[:style],
              color: options[:color],
              fontcolor: options[:color],
              penwidth: options[:stroke],
              fontsize: fontsize
          }.merge(inherited_render_options)
      }

      if options[:colorize] || root.colorize_edges?
        edge_color = next_colorizer_color
        pointers.last[:options].merge!({
                                           color: edge_color,
                                           fontcolor: edge_color
                                       })
      end

    end

    def render_pointer(pointer, renderer)
      other = pointer[:other]
      while (other.in_rollup? && !other.on_top_rollup?) do
        other = other.parent
      end
      return if other.under_rollup?

      from = self
      while (from.in_rollup? && !from.on_top_rollup?) do
        from = from.parent
      end

      return if from.in_skip?

      return if from == self && from.in_rollup?
      return if from == other
      return if already_added_connection?(other)

      if other.in_skip?
        others = resolve_skipped_others other
      else
        others = [other]
      end

      others.each do |other_to_render|
        edge_heads << other_to_render
        render_options = pointer[:options]
        renderer.render_edge(from, other_to_render, render_options)
      end
    end

    def already_added_connection?(other)
      edge_heads.include? other
    end

    def resolve_skipped_others(skipped)
      resolved = []
      skipped.pointers.each { |pointer|
        next_in_line = pointer[:other]
        if next_in_line.in_skip?
          resolved += resolve_skipped_others next_in_line
        else
          resolved << next_in_line
        end
      }
      resolved
    end

    def next_colorizer_color
      @@colorizer.next
    end
  end
end