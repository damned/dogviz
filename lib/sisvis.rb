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
    def doclink(url)
      setup_render_attributes(URL: url)
    end
    def setup_render_attributes(attributes)
      @attributes = {} if @attributes.nil?
      @attributes.merge!(attributes)
    end
    def apply_render_attributes
      @attributes.each do |key, value|
        node[key] = value
      end
    end
    def rollup?
      @rollup
    end
    def rollup!
      @rollup = true
      self
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
      @edge_heads = []

      rollup! if options[:rollup]
      options.delete(:rollup)

      @render_options = options
      setup_render_attributes label: name

      parent.register name, self
    end


    def render_node
      default_options = {:shape => 'box', :style => ''}
      parent_node.add_nodes(id, default_options.merge(@render_options))
      apply_render_attributes
    end

    def node
      graph.find_node(id)
    end

    def points_to_all(*others)
      others.each {|other|
        points_to other
      }
    end

    def points_to(other, options = {})
      setup_render_edge(other, options)
    end

    def pointees
      pointers.map {|e|
        e[:other]
      }
    end

    def render
      render_node unless in_rollup?
    end
    def render_edges
      pointers.each {|p| render_pointer p }
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

    def render_pointer(pointer)
      other = pointer[:other]
      while (other.in_rollup? && !other.on_top_rollup?) do
        other = other.parent
      end
      return if other.under_rollup?

      from = self
      while (from.in_rollup? && !from.on_top_rollup?) do
        from = from.parent
      end

      return if from == self && from.in_rollup?

      return if from == other
      return if edge_heads.include? other

      edge_heads << other
      edge = graph.add_edges from.id, other.id
      pointer[:options].each { |key, value|
        edge[key] = value unless value.nil?
      }
      edge
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

      init_rollup options

      setup_render_attributes label: name

      @render_options = options

      parent.register name, self
    end

    def register(name, thing)
      @by_name.register name, thing
      parent.register name, thing
    end

    def render
      if on_top_rollup?
        render_node parent_node
      elsif !under_rollup?
        render_subgraph parent_node
      end

      children.each {|c|
        c.render
      }
    end

    def render_edges
      children.each {|c|
        c.render_edges
      }
    end

    def node
      if render_type == :node
        graph.find_node(render_id)
      elsif render_type == :subgraph
        @subgraph
      end
    end

    private

    def render_subgraph(parent_node)
      @render_type = :subgraph
      @render_id = cluster_prefix + id
      @subgraph = parent_node.add_graph(@render_id, render_options)
      apply_render_attributes
    end

    def render_node(parent_node)
      @render_type = :node
      @render_id = id
      clean_node_attributes
      parent_node.add_nodes(@render_id, {:shape => 'box', :style => ''}.merge(render_options))
      apply_render_attributes
    end

    def clean_node_attributes
      render_options.delete(:rank)
      render_options.delete(:cluster)
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
      @graph = GraphViz.digraph(@title)
      @graph[render_hints]
    end

    def node
      graph
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
      children.each {|c|
        c.render
      }
      children.each {|c|
        c.render_edges
      }
      @rendered = true
      @graph
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
