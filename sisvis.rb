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
    def thing(name)
      Thing.new self, name
    end
    def container(name, options={})
      Container.new self, name, options
    end
  end

  class Thing
    include Common
    attr_reader :parent
    attr_reader :name, :id, :node

    def initialize(parent, name, options = {})
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      if parent.rollup?
        rollup!
      else
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

      from = self
      while (from.rollup? && from.parent.rollup?) do
        from = from.parent
      end

      return if from == other

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
    attr_reader :name, :id, :node

    def initialize(parent, name, options = {})
      @registry = Registry.new
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      @rollup = false

      prefix = cluster_prefix(options)
      if options[:rollup]
        options.delete :rollup
        rollup!
      end
      if parent.rollup?
        rollup!
      end
      if rollup?
        if !parent.rollup?
          default_options = {:shape => 'box', :style => ''}
          @node = parent_node.add_nodes(id, default_options.merge(options))
        end
      else
        @node = parent_node.add_graph(prefix + id, options)
      end

      node[:label] = name unless node.nil?
      parent.register name, self
    end

    def register(name, thing)
      @registry.register name, thing
      parent.register name, thing
    end
    def find(name)
      @registry.lookup name
    end

    private

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

  class System
    include Parent
    extend Forwardable
    def_delegator :@graph, :output
    attr_reader :graph
    def initialize(name, hints = {splines: 'line'})
      @registry = Registry.new
      @graph = GraphViz.digraph(name)
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
  end

  class Registry
    def initialize
      @registry = {}
    end

    def register(name, thing)
      if @registry.has_key?(name)
        @registry[name] = StandardError.new "More than one object registered of name '#{name}' - you'll need to search in a narrower context"
      else
        @registry[name] = thing
      end
    end

    def lookup(name)
      found = @registry[name]
      raise found if found.is_a?(Exception)
      found
    end
  end

end
