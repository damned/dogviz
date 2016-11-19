require_relative 'lookup_error.rb'
require_relative 'missing_match_block_error.rb'
require_relative 'duplicate_lookup_error.rb'

module Dogviz
  class Registry
    def initialize(context)
      @context = context
      @by_name = {}
      @all = []
    end

    def register(name, thing)
      @all << thing
      if @by_name.has_key?(name)
        @by_name[name] = DuplicateLookupError.new @context, name
      else
        @by_name[name] = thing
      end
    end

    def find(&matcher)
      raise LookupError.new(@context, "need to provide match block") unless block_given?
      @all.find &matcher
    end

    def find_all(&matcher)
      raise MissingMatchBlockError.new(@context) unless block_given?
      @all.select &matcher
    end

    def lookup(name)
      found = @by_name[name]
      raise LookupError.new(@context, "could not find '#{name}'") if found.nil?
      raise found if found.is_a?(Exception)
      found
    end
  end
end