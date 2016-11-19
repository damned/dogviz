module Dogviz
  class MissingMatchBlockError < LookupError
    def initialize(context)
      super context, 'need to provide match block'
    end
  end
end