require_relative 'setup_tests'
require_relative 'svg_graph'

module Tests
  class TestDogvizFunctionally < Test::Unit::TestCase

    def outfile(ext)
      "/tmp/dogviz_functional_test.#{ext}"
    end

    def read_outfile(ext)
      File.read outfile(ext)
    end

    def setup
      File.delete outfile('svg') if File.exist?(outfile('svg'))
    end

    include Dogviz
    class Family < Dogviz::System
      attr_reader *%i(cat dog mum son)
      def initialize
        super 'family'

        house = container 'household'

        @cat = house.thing 'cat'
        @dog = house.thing 'dog'

        @mum = house.thing 'mum'
        @son = house.thing 'son'

        mum.points_to son, name: 'parents'
        son.points_to mum, name: 'ignores'

        cat.points_to dog, name: 'chases'
        dog.points_to son, name: 'follows'
      end
    end

    def test_outputs_svg_graph

      sys = Family.new

      sys.output svg: outfile('svg')

      graph = SvgGraph.parse_file outfile('svg')

      assert_include graph.title, 'family'
      assert_equal ['household'], graph.names_of.containers
      assert_equal ['cat', 'dog', 'son', 'mum'], graph.names_of.things
      assert_equal ['chases', 'follows', 'parents', 'ignores'], graph.names_of.edges
    end

  end
end