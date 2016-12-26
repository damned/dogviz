require_relative 'common'
require_relative 'nominator'
require_relative 'parent'

module Dogviz
  class Container
    include Common
    include Nominator
    include Parent

    attr_reader :parent
    attr_reader :name, :id, :node, :render_type, :render_options, :children

    def initialize(parent, name, options = {})
      @children = []
      @by_name = Registry.new name
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      @skip = false
      @info = {}

      init_rollup options

      setup_render_attributes label: name
      default_bounded_option(options)

      @render_options = options.merge(inherited_render_options)

      parent.register name, self
    end

    def register(name, thing)
      @by_name.register name, thing
      parent.register name, thing
    end

    def render(renderer)
      if on_top_rollup?
        do_render_node renderer
      elsif !under_rollup?
        do_render_subgraph renderer
      end

      children.each { |c|
        c.render renderer
      }
    end

    def render_edges(renderer)
      children.each { |c|
        c.render_edges renderer
      }
    end

    private

    def do_render_subgraph(renderer)
      @render_type = :subgraph
      @subgraph = renderer.render_subgraph(parent, id, render_options.merge(@attributes))
    end

    def do_render_node(renderer)
      @render_type = :node
      renderer.render_node(parent, id, render_options.merge(@attributes))
    end

    def init_rollup(options)
      @rollup = false
      rollup! if options[:rollup]
      options.delete(:rollup)
    end

    def default_bounded_option(options)
      bounded = true
      if options.has_key? :bounded
        bounded = options[:bounded]
      end
      options[:bounded] = bounded
    end
  end
end