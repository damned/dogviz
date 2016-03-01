require 'ruby-graphviz'

module Dogviz
  module Common
    def create_id(name, parent)
      parts = []
      parts << parent.id if parent.respond_to? :id
      parts += name.split /\s/
      parts.join '_'
    end
    def ancestors
      ancestors = [parent]
      loop do
        break unless ancestors.last.respond_to?(:parent)
        ancestors << ancestors.last.parent
      end
      ancestors
    end
    def doclink(url)
      setup_render_attributes(URL: url)
    end
    def setup_render_attributes(attributes)
      @attributes = {} if @attributes.nil?
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

    def under_rollup?
      ancestors.any? &:rollup?
    end
    def in_rollup?
      rollup? || under_rollup?
    end
    def on_top_rollup?
      rollup? && !under_rollup?
    end
  end
  module Parent
    def find_all(&matcher)
      raise MissingMatchBlockError.new unless block_given?
      @by_name.find_all &matcher
    end
    def find(name=nil, &matcher)
      if block_given?
        @by_name.find &matcher
      else
        raise 'Need to provide name or block' if name.nil?
        @by_name.lookup name
      end
    end
    def thing(name, options={})
      add Thing.new self, name, options
    end
    def container(name, options={})
      add Container.new self, name, options
    end
    def logical_container(name, options={})
      add LogicalContainer.new self, name, options
    end
    def group(name, options={})
      logical_container name, options
    end
    def add(child)
      @children << child
      child
    end
  end

  class Thing
    include Common
    attr_reader :parent
    attr_reader :name, :id, :pointers, :edge_heads

    def initialize(parent, name, options = {})
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      @pointers = []
      @rollup = false
      @skip = false
      @edge_heads = []

      rollup! if options[:rollup]
      options.delete(:rollup)

      @render_options = options
      setup_render_attributes label: name

      parent.register name, self
    end

    def do_render_node(renderer)
      render_options = @render_options
      attributes = @attributes
      renderer.render_node(parent, id, render_options, attributes)
    end

    def points_to_all(*others)
      others.each {|other|
        points_to other
      }
    end

    def points_to(other, options = {})
      setup_render_edge(other, options)
      other
    end

    def render(renderer)
      do_render_node(renderer) unless in_rollup?
    end

    def render_edges(renderer)
      pointers.each {|p|
        render_pointer p, renderer
      }
    end

    private

    def setup_render_edge(other, options)
      pointers << {
          other: other,
          options: {
              label: options[:name],
              style: options[:style]
          }
      }
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

      return if from.skip?

      return if from == self && from.in_rollup?
      return if from == other
      return if already_added_connection?(other)

      if other.skip?
        others = resolve_skipped_others other
      else
        others = [other]
      end

      others.each do |other|
        edge_heads << other
        render_options = pointer[:options]
        renderer.render_edge(from, other, render_options)
      end
    end

    def already_added_connection?(other)
      edge_heads.include? other
    end

    def resolve_skipped_others(other)
      other.pointers.map {|pointer| pointer[:other]}
    end
  end

  class Container
    include Common
    include Parent
    attr_reader :parent
    attr_reader :name, :id, :node, :render_id, :render_type, :render_options, :children

    def initialize(parent, name, options = {})
      @children = []
      @by_name = Registry.new
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      @skip = false

      init_rollup options

      setup_render_attributes label: name

      @render_options = options

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

      children.each {|c|
        c.render renderer
      }
    end

    def render_edges(renderer)
      children.each {|c|
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

  class LogicalContainer < Container
    def initialize(parent, name, options)
      super parent, name, options.merge(cluster: false)
    end
  end

  require 'date'

  class GraphvizRenderer
    attr_reader :graph

    def initialize(title, hints)
      @graph = GraphViz.digraph(title)
      @graph[hints]
      @subgraphs = {}
      @nodes = {}
    end

    def render_edge(from, other, options)
      edge = graph.add_edges from.id, other.id
      options.each { |key, value|
        edge[key] = value unless value.nil?
      }
      edge
    end

    def render_node(parent, id, options, attributes)
      clean_node_options options
      default_options = {:shape => 'box', :style => ''}
      node = parent_node(parent).add_nodes(id, default_options.merge(options))
      apply_render_attributes node, attributes
    end

    def render_subgraph(parent, id, options, attributes)
      subgraph = parent_node(parent).add_graph(id, options)
      apply_render_attributes subgraph, attributes
      @subgraphs[id] = subgraph
      subgraph
    end

    private

    def clean_node_options(options)
      options.delete(:rank)
      options.delete(:cluster)
      options
    end

    def parent_node(parent)
      return graph unless parent.respond_to?(:render_id)
      node = graph.search_node(parent.render_id)
      return node unless node.nil?
      subgraph = @subgraphs[parent.render_id]
      raise "couldn't find node or graph: #{parent.render_id}, out of graphs: #{graph_ids}" if subgraph.nil?
      subgraph
    end

    def apply_render_attributes(node, attributes)
      attributes.each do |key, value|
        node[key] = value
      end
    end
  end

  class System
    include Parent

    attr_reader :render_hints, :title, :children, :graph

    alias :name :title

    def initialize(name, hints = {splines: 'line'})
      @children = []
      @by_name = Registry.new
      @render_hints = hints
      @title = create_title(name)
      @rendered = false
    end

    def output(*args)
      render
      out = graph.output *args
      puts "Created output: #{args.join ' '}"
      out
    end

    def render(type=:graphviz)
      return @graph if @rendered
      raise "dunno bout that '#{type}', only know :graphviz" unless type == :graphviz

      renderer = GraphvizRenderer.new @title, render_hints

      children.each {|c|
        c.render renderer
      }
      children.each {|c|
        c.render_edges renderer
      }
      @rendered = true
      @graph = renderer.graph
    end

    def rollup?
      false
    end

    def register(name, thing)
      @by_name.register name, thing
    end

    private

    def create_title(name)
      now = DateTime.now
      "#{now.strftime '%H:%M'} #{name} #{now.strftime '%F'}"
    end
  end

  class LookupError < StandardError
  end
  class MissingMatchBlockError < LookupError
    def initialize
      super 'need to provide match block'
    end
  end
  class DuplicateLookupError < LookupError
    def initialize(name)
      super "More than one object registered of name '#{name}' - you'll need to search in a narrower context"
    end
  end
  class Registry
    def initialize
      @by_name = {}
      @all = []
    end

    def register(name, thing)
      @all << thing
      if @by_name.has_key?(name)
        @by_name[name] = DuplicateLookupError.new name
      else
        @by_name[name] = thing
      end
    end

    def find(&matcher)
      raise LookupError.new("need to provide match block") unless block_given?
      @all.find &matcher
    end

    def find_all(&matcher)
      raise MissingMatchBlockError.new unless block_given?
      @all.select &matcher
    end

    def lookup(name)
      found = @by_name[name]
      raise LookupError.new("could not find '#{name}'") if found.nil?
      raise found if found.is_a?(Exception)
      found
    end
  end

end
