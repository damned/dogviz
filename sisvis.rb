require 'ruby-graphviz'

module Sisvis
  module Common
    def create_id(name, parent)
      parts = []
      parts << parent.id if parent.respond_to? :id
      parts += name.split /\s/
      parts.join '_'
    end
    def g
      parent.g
    end
    def parent_node
      parent.node
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
      default_options = {:shape => 'box', :style => ''}
      @node = parent_node.add_nodes(id, default_options.merge(options))
      parent.register name, self
      node[:label] = name
    end

    def points_to(*others)
      others.each {|other|
        other_thing = if other.is_a? Thing
                        other
                      else
                        other.entry_process
                      end
        g.add_edges id, other_thing.id
      }
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

  class Container
    include Common
    attr_reader :parent
    attr_reader :name, :id, :node

    def initialize(parent, name, options = {})
      @registry = Registry.new
      @parent = parent
      @name = name
      @id = create_id(name, parent)

      prefix = cluster_prefix(options)
      @node = parent_node.add_graph(prefix + id, options)

      node[:label] = name
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
  module Creators
    def box(name)
      Box.new(self, name)
    end
    def pipeline(name)
      Pipeline.new(self, name)
    end
    def thing(name)
      Thing.new self, name
    end
    def process(name)
      Process.new self, name
    end
    def external(name)
      External.new self, name
    end
    def grouping(name, options = {})
      Grouping.new self, name, options
    end
  end
  class System
    attr_reader :g
    def initialize(g)
      @registry = Registry.new
      @g = g
      g[splines: 'line']
    end
    include Creators
    def node
      g
    end
    def register(name, thing)
      @registry.register name, thing
    end
  end
  class Box < Container
    def initialize(parent, name)
      super parent, name
    end
    def service(name)
      Service.new self, name
    end
    def process(name)
      Process.new self, name
    end
    def entry_process
      raise 'if you wanna use entry_process, you got to set it first!' if @entry_process.nil?
      @entry_process
    end
    attr_writer :entry_process
  end
  class Service < Container
    include Creators
  end
  class Pipeline < Container
    def initialize(parent, name, options={})
      super parent, name, options

    end
    include Creators
    def stage(name)
      stage = thing name
      stage.node[:URL]="http://go/tw.#{name}"
      stage
    end
  end
  class Grouping < Container
    def initialize(parent, name, options)
      super parent, name, options.merge(cluster: false)
    end
    include Creators
  end
  class Process < Thing
    def initialize(parent, name)
      super parent, name, style: 'filled'
    end
    def calls(*callees)
      points_to *callees
    end
    def doclink(url)
      node[:URL] = url
    end
  end
  class External < Thing
    def initialize(parent, name)
      super parent, name, color: 'lightyellow', style: 'filled'
    end
  end
end
