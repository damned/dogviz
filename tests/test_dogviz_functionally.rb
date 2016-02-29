require_relative 'setup_tests'
require_relative 'svg_graph'

module Tests
  class TestDogvizFunctionally < Test::Unit::TestCase

    def svg_outfile
      '/tmp/dogviz_functional_test.svg'
    end

    def setup
      File.delete svg_outfile if File.exist?(svg_outfile)
    end

    include Dogviz
    def test_outputs_svg_graph

      sys = System.new 'family'

      house = sys.container 'household'

      cat = house.thing 'cat'
      dog = house.thing 'dog'

      mum = house.thing 'mum'
      son = house.thing 'son'

      mum.points_to son, name: 'parents'
      son.points_to mum, name: 'respects'

      cat.points_to dog, name: 'chases'
      dog.points_to son, name: 'follows'

      sys.output svg: svg_outfile

      graph = SvgGraph.parse_file svg_outfile

      assert_include graph.title, 'family'
      assert_equal ['household'], graph.names_of.containers
      assert_equal ['cat', 'dog', 'son', 'mum'], graph.names_of.things
      assert_equal ['chases', 'follows', 'parents', 'respects'], graph.names_of.edges
    end

  end
end