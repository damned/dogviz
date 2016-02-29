require 'dogviz'

module WebsiteDomain
  include Dogviz
  module Creators
    def box(name, options={})
      add Box.new(self, name, options)
    end
    def pipeline(name)
      add Pipeline.new(self, name)
    end
    def lb(name)
      add LoadBalancer.new self, name
    end
    def process(name)
      add Process.new self, name
    end
    def external(name, options={})
      add External.new self, name, options
    end
    def grouping(name, options = {})
      add Grouping.new self, name, options
    end
    def data_centre(name)
      add DataCentre.new self, name
    end
    def user(name)
      add User.new self, name
    end
  end
  class Grouping < LogicalContainer
    include Creators
  end
  class WebsiteSystem < System
    include Creators
    def render
      puts 'Rendering...' unless @rendered
      super
    end
    def rollup_by_class(type)
      find_all { |n|
        n.is_a?(type)
      }.each &:rollup!
    end
    def   rollup_names_starting(start)
      find_all { |n|
        n.name.start_with? start
      }.each &:rollup!
    end
    def rollup_names_including(substring)
      find_all { |n|
        n.name.include? substring
      }.each &:rollup!
    end
  end
  class Box < Container
    def initialize(parent, name, options={})
      super parent, name, {style: 'filled', color: '#ffaaaa'}.merge(options)
    end
    def service(name, options={})
      add Service.new self, name, options
    end
    def process(name)
      add Process.new self, name
    end
  end
  class Service < Container
    def initialize(parent, name, options={})
      super parent, name, options.merge(color: '#cccccc', style: 'filled')
    end
    include Creators
  end
  class DataCentre < Container
    def initialize(parent, name, options={})
      super parent, name
    end
    include Creators
  end
  class Pipeline < Container
    def initialize(parent, name, options={})
      super parent, name, options.merge(color: '#c8f8c8', style: 'filled')
    end
    include Creators
    def stage(name)
      add Stage.new self, name
    end
  end
  class Stage < Thing
    def initialize(parent, name)
      super parent, name, color: '#aaccaa', style: 'filled'
      doclink("http://go/#{name}")
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
    def initialize(parent, name, options={})
      super parent, name, options.merge(color: 'lightyellow', style: 'filled')
    end
  end
  class User < Thing
    def initialize(parent, name)
      super parent, name, shape: 'circle', color: 'brown'
    end
    def uses(used)
      points_to used
    end
    def uses_all(*useds)
      points_to_all *useds
    end
  end
  class LoadBalancer < Thing
    def initialize(parent, name)
      super parent, name, color: '#ff6666', style: 'filled'
    end
  end

  class Repo
    def initialize(organisation, name)
      @name = name
      @organisation = organisation
    end

    def url
      "https://github.com/#{@organisation}/#{@name}"
    end

    def source(path)
      "#{url}/blob/master/#{path}"
    end

    def to_s
      url
    end
  end

end
