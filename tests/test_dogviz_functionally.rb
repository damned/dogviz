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

    def test_flow_generates_precise_sequence
      sys = System.new 'takeaway'
      eater = sys.thing 'eater'
      server = sys.thing 'server'
      cook = sys.thing 'cook'

      order = sys.flow 'order'
      order.flows eater, 'asks for burger',
                  server, 'passes order',
                  cook, server, eater

      order.output sequence: outfile('seq.txt')

      definition = read_outfile('seq.txt')

      assert_equal [
                       'eater -> server: asks for burger',
                       'server -> cook: passes order',
                       'cook -> server:',
                       'server -> eater:',
                   ].join("\n"), definition
    end

    def test_flow_generates_precise_sequence_with_action
      sys = System.new 'takeaway'
      eater = sys.thing 'eater'
      server = sys.thing 'server'
      cook = sys.thing 'cook'

      order = sys.flow 'order'
      order.flows eater, 'orders',
                  server, 'creates order',
                  cook.does('cooks burger'),
                  'burger', server,
                  'burger', eater

      order.output sequence: outfile('seq.txt')
      definition = read_outfile('seq.txt')

      assert_equal([
                       'eater -> server: orders',
                       'server -> +cook: creates order',
                       'note right of cook',
                       '  cooks burger',
                       'end note',
                       'cook -> -server: burger',
                       'server -> eater: burger',
                   ].join("\n"), definition)
    end

    def xtest_flows_render_sequence_diagrams_and_form_edges

      sys = System.new 'service'

      organisation = sys.container 'organisation'

      customer = sys.thing 'customer'

      support = organisation.thing 'support phone line'
      ivr = organisation.thing 'ivr'
      first = organisation.thing 'first level support'
      second = organisation.thing 'second level support'

      complaint = sys.flow 'complaint'

      complain.flows customer, 'calls',
          support, 'connects to',
          ivr, ''


    end

  end
end