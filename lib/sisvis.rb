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
      node[:URL] = url unless node.nil?
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
    attr_reader :name, :id, :node, :pointees

    def initialize(parent, name, options = {})
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      @pointees = []
      if parent.rollup? || options[:rollup]
        rollup!
      else
        options.delete(:rollup)
        default_options = {:shape => 'box', :style => ''}
        @node = parent_node.add_nodes(id, default_options.merge(options))
        node[:label] = name
      end
      parent.register name, self
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

      point_to_node(from, options, other)
    end

    private

    def point_to_node(from, options, other)
      pointees << other
      edge = graph.add_edges from.id, other.id
      edge[:label] = options[:name] if options.has_key?(:name)
      edge[:style] = options[:style] if options.has_key?(:style)
      edge
    end
  end

  class Container
    include Common
    include Parent
    attr_reader :parent
    attr_reader :name, :id, :node, :rendered_id

    def initialize(parent, name, options = {})
      @registry = Registry.new
      @parent = parent
      @name = name
      @id = create_id(name, parent)

      prefix = cluster_prefix(options)
      init_rollup options, parent
      if rollup?
        if !parent.rollup?
          options.delete(:rank)
          create_as_node(options)
        end
      else
        create_as_subgraph(options, prefix)
      end

      node[:label] = name unless node.nil?
      parent.register name, self
    end

    def register(name, thing)
      @registry.register name, thing
      parent.register name, thing
    end

    private

    def create_as_subgraph(options, prefix)
      @rendered_id = prefix + id
      @node = parent_node.add_graph(rendered_id, options)
    end

    def create_as_node(options)
      default_options = {:shape => 'box', :style => ''}
      @node = parent_node.add_nodes(id, default_options.merge(options))
      @rendered_id = id
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
    extend Forwardable
    def_delegator :@graph, :output
    attr_reader :graph
    def initialize(name, hints = {splines: 'line'})
      @registry = Registry.new
      @graph = GraphViz.digraph(create_title(name))
      graph[hints]
    end
    def node
      graph
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
