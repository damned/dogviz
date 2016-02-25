require 'ruby-graphviz'

module Sisvis
  module Common
    def create_id(name, parent)
      parts = []
      parts << parent.id if parent.respond_to? :id
      parts += name.split /\s/
      parts.join '_'
    end
    def graph
      parent.graph
    end
    def parent_node
      parent.node
    end
    def root
      ancestor = self
      while ancestor.respond_to?(:parent)
        ancestor = ancestor.parent
      end
      ancestor
    end
    def doclink(url)
      setup_render_attributes(URL: url)
      apply_render_attributes
    end
    def setup_render_attributes(attributes)
      @attributes ||= {}
      @attributes.merge!(attributes)
    end
    def apply_render_attributes
      return if node.nil?
      @attributes.each do |key, value|
        node[key] = value
      end
    end
    def rollup?
      @rollup
    end
    def rollup!
      @rollup = true
    end
  end
  module Parent
    def find(name)
      @registry.lookup name
    end
    def thing(name, options={})
      Thing.new self, name, options
    end
    def container(name, options={})
      Container.new self, name, options
    end
    def logical_container(name, options={})
      LogicalContainer.new self, name, options
    end
    def group(name, options={})
      logical_container name, options
    end
  end

  class Thing
    include Common
    attr_reader :parent
    attr_reader :name, :id, :node, :edges

    def initialize(parent, name, options = {})
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      @edges = []
      if parent.rollup? || options[:rollup]
        rollup!
      else
        options.delete(:rollup)
        setup_render_node(name, options)
        render_node
      end
      parent.register name, self
    end

    def setup_render_node(name, options)
      default_options = {:shape => 'box', :style => ''}
      setup_render_attributes label: name
      @render_options = default_options.merge(options)
    end

    def render_node
      @node = parent_node.add_nodes(id, @render_options)
      apply_render_attributes
    end

    def points_to_all(*others)
      others.each {|other|
        points_to other
      }
    end

    def points_to(other_thing, options = {})
      other = other_thing
      while (other.rollup? && other.parent.rollup?) do
        other = other.parent
      end

      return if other.is_a?(Thing) && other.rollup?

      from = self
      while (from.rollup? && from.parent.rollup?) do
        from = from.parent
      end

      return if from == self && from.rollup?

      return if from == other
      return if pointees.include? other

      edge = setup_render_edge(from, other, options)
      render_edge(edge)
    end

    def pointees
      edges.map {|e|
        e[:other]
      }
    end

    private


    def setup_render_edge(from, other, options)
      edges << {
          from: from,
          other: other,
          options: {
              label: options[:name],
              style: options[:style]
          }
      }
      edge = edges.last
    end

    def render_edge(edge)
      rendered_edge = graph.add_edges edge[:from].id, edge[:other].id
      edge[:options].each { |key, value|
        rendered_edge[key] = value unless value.nil?
      }
      rendered_edge
    end
  end

  class Container
    include Common
    include Parent
    attr_reader :parent
    attr_reader :name, :id, :node, :render_id, :render_options

    def initialize(parent, name, options = {})
      @registry = Registry.new
      @parent = parent
      @name = name
      @id = create_id(name, parent)

      prefix = cluster_prefix(options)
      init_rollup options, parent
      setup_render_attributes label: name
      if rollup?
        if !parent.rollup?
          options.delete(:rank)
          setup_node_render(options)
          render_node
        end
      else
        setup_subgraph_render(options, prefix)
        render_subgraph
      end

      parent.register name, self
    end

    def register(name, thing)
      @registry.register name, thing
      parent.register name, thing
    end

    private

    def setup_subgraph_render(options, prefix)
      @render_id = prefix + id
      @render_options = options
    end

    def setup_node_render(options)
      @render_id = id
      default_options = {:shape => 'box', :style => ''}
      @render_options = default_options.merge(options)
    end

    def render_subgraph
      @node = parent_node.add_graph(render_id, render_options)
      apply_render_attributes
    end

    def render_node
      @node = parent_node.add_nodes(render_id, render_options)
      apply_render_attributes
    end

    def init_rollup(options, parent)
      @rollup = false
      rollup! if options[:rollup]
      options.delete(:rollup)
      if parent.rollup?
        rollup!
      end
    end

    def cluster_prefix(options)
      is_cluster = true
      if options.has_key? :cluster
        is_cluster = options[:cluster]
        options.delete :cluster
      end
      cluster_prefix = (is_cluster ? 'cluster_' : '')
    end

  end

  class LogicalContainer < Container
    def initialize(parent, name, options)
      super parent, name, options.merge(cluster: false)
    end
  end

  require 'date'

  class System
    include Parent

    attr_reader :render_hints, :title

    def initialize(name, hints = {splines: 'line'})
      @registry = Registry.new
      @render_hints = hints
      @title = create_title(name)
      @graph = GraphViz.digraph(@title)
      @graph[render_hints]
    end
    def node
      graph
    end
    def graph
      render :graphviz
    end
    def output(*args)
      graph.output *args
    end
    def render(type)
      raise "dunno bout that '#{type}', only know :graphviz" unless type == :graphviz
      @graph
    end
    def rollup?
      false
    end
    def register(name, thing)
      @registry.register name, thing
    end
    private
    def create_title(name)
      now = DateTime.now
      "#{now.strftime '%H:%M'} #{name} #{now.strftime '%F'}"
    end
  end

  class LookupError < StandardError
  end
  class DuplicateLookupError < LookupError
    def initialize(name)
      super "More than one object registered of name '#{name}' - you'll need to search in a narrower context"
    end
  end
  class Registry
    def initialize
      @registry = {}
    end

    def register(name, thing)
      if @registry.has_key?(name)
        @registry[name] = DuplicateLookupError.new name
      else
        @registry[name] = thing
      end
    end

    def lookup(name)
      found = @registry[name]
      raise LookupError.new("could not find '#{name}'") if found.nil?
      raise found if found.is_a?(Exception)
      found
    end
  end

end
