module Dogviz
  class DuplicateLookupError < LookupError
    def initialize(context, name)
      super context, "More than one object registered of name '#{name}' - you'll need to search in a narrower context"
    end
  end
end