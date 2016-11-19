module Dogviz
  class Colorizer
    def initialize
      @i = 0
      @colors = %w(#9e0142
#d53e4f
#e45d33
#ed9e61
#762a83
#9970ab
#c6f578
#abdda4
#66c2a5
#3288bd
#5e4fa2)
    end

    def next
      color = @colors[@i]
      @i += 1
      @i = 0 unless @i < @colors.length
      color
    end
  end
end