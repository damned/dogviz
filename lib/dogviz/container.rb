require_relative 'common'
require_relative 'nominator'
require_relative 'parent'

module Dogviz
  class Container
    include Common
    include Nominator
    include Parent

    attr_reader :parent
    attr_reader :name, :id, :node, :render_id, :render_type, :render_options, :children

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

      @render_options = options.merge inherited_render_options

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
      render_id = cluster_prefix + id
      attributes = @attributes
      @render_id = render_id
      @subgraph = renderer.render_subgraph(parent, render_id, render_options, attributes)
    end

    def do_render_node(renderer)
      @render_type = :node
      @render_id = id
      render_id = @render_id
      attributes = @attributes
      renderer.render_node(parent, render_id, render_options, attributes)
    end

    def init_rollup(options)
      @rollup = false
      rollup! if options[:rollup]
      options.delete(:rollup)
    end

    def cluster_prefix
      is_cluster = true
      if @render_options.has_key? :cluster
        is_cluster = @render_options[:cluster]
        @render_options.delete :cluster
      end
      cluster_prefix = (is_cluster ? 'cluster_' : '')
    end
  end
end