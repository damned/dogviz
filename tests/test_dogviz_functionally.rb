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

    def describe_household
      sys = System.new 'family'

      house = sys.container 'household'

      cat = house.thing 'cat'
      dog = house.thing 'dog'

      mum = house.thing 'mum'
      son = house.thing 'son'

      mum.points_to son, name: 'parents'
      son.points_to mum, name: 'ignores'

      cat.points_to dog, name: 'chases'
      dog.points_to son, name: 'follows'
      sys
    end

    def test_outputs_svg_graph

      sys = describe_household

      sys.output svg: outfile('svg')

      graph = SvgGraph.parse_file outfile('svg')

      assert_include graph.title, 'family'
      assert_equal ['household'], graph.names_of.containers
      assert_equal ['cat', 'dog', 'son', 'mum'], graph.names_of.things
      assert_equal ['chases', 'follows', 'parents', 'ignores'], graph.names_of.edges
    end

    def test_generates_sequence_diagram_definition

      sys = describe_household

      sys.output sequence: outfile('seq.txt')

      definition = read_outfile('seq.txt')

      assert_include definition, 'cat -> dog: chases'
      assert_include definition, 'dog -> son: follows'
      assert_include definition, 'mum -> son: parents'
      assert_include definition, 'son -> mum: ignores'
    end
  end
end