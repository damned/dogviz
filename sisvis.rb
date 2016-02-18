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
    def doclink(url)
      node[:URL] = url
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

    def points_to_all(*others)
      others.each {|other|
        points_to other
      }
    end
    def points_to(other, options = {})
      other_thing = if other.is_a? Thing
                      other
                    else
                      other.entry_process
                    end
      edge = g.add_edges id, other_thing.id
      edge[:label] = options[:name] if options.has_key?(:name)
      edge[:style] = options[:style] if options.has_key?(:style)
      edge
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
    def lb(name)
      LoadBalancer.new self, name
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
    def initialize(g, hints = {splines: 'line'})
      @registry = Registry.new
      @g = g
      g[hints]
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
      super parent, name, {style: 'filled', color: '#ffaaaa'}
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
    def initialize(parent, name, options={})
      super parent, name, options.merge(color: '#cccccc', style: 'filled')
    end
    include Creators
  end
  class Pipeline < Container
    def initialize(parent, name, options={})
      super parent, name, options.merge(color: '#c8f8c8', style: 'filled')
    end
    include Creators
    def stage(name)
      Stage.new self, name
    end
  end
  class Stage < Thing
    def initialize(parent, name)
      super parent, name, color: '#aaccaa', style: 'filled'
      node[:URL]="http://go/tw.#{name}"
    end
    def deploys(*apps)
      apps.each {|app|
        points_to app, name: 'deploys', style: 'dotted'
      }
    end
    def triggers(*stages)
      stages.each {|stage|
        points_to stage, name: 'triggers', color: '#00bb00'
      }
    end
    def configures(*things)
      things.each {|thing|
        points_to thing, name: 'configures', style: 'dashed'
      }
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
    def calls_all(*callees)
      points_to_all *callees
    end
    def calls(callee, options={})
      points_to callee, options
    end
  end
  class External < Thing
    def initialize(parent, name)
      super parent, name, color: 'lightyellow', style: 'filled'
    end
  end
  class LoadBalancer < Thing
    def initialize(parent, name)
      super parent, name, color: '#ff6666', style: 'filled'
      doclink 'https://mycloud.rackspace.com/cloud/553357/load_balancers'
    end
  end

  class Repo
    def initialize(name)
      @name = name
    end

    def url
      "https://github.com/www-thoughtworks-com/#{@name}"
    end

    def source(path)
      "#{url}/blob/master/#{path}"
    end

    def to_s
      url
    end
  end
end
