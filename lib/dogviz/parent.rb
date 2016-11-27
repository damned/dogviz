module Dogviz
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

    def root?
      not respond_to?(:parent)
    end
  end
end