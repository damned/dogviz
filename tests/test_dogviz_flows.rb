require_relative 'setup_tests'
require_relative 'graph_checking'

module Tests
  class TestDogvizFlows < Test::Unit::TestCase
    include GraphChecking

    def outfile(ext)
      "/tmp/dogviz_flow_test.#{ext}"
    end

    def read_outfile(ext)
      File.read outfile(ext)
    end

    include Dogviz

    def test_flow_generates_precise_sequence
      create_takeaway

      order = sys.flow 'order'
      order.flows sys.eater, 'gimme burger',
                  sys.server, 'passes order',
                  sys.cook, sys.server, sys.eater

      definition = sequence_definition(order)

      assert_equal [
                       'eater -> server: gimme burger',
                       'server -> cook: passes order',
                       'cook -> server:',
                       'server -> eater:',
                   ].join("\n"), definition
    end

    def test_nested_flow_syntax
      create_takeaway

      order = sys.flow('order').involves(sys.server, sys.cook)

      sys.server.receives burger: { 'gimme burger' => 'here ya go' }, 
                          dessert: 'gimme dessert'
      sys.cook.receives order: 'passes order'

      order.from(sys.eater) {
        sys.server.burger {
          sys.cook.order
        }
        sys.server.dessert
      }

      definition = sequence_definition(order)

      assert_equal [
                    'eater -> server: gimme burger',
                    'server -> cook: passes order',
                    'cook -> server:',
                    'server -> eater: here ya go',
                    'eater -> server: gimme dessert',
                    'server -> eater:',
                  ].join("\n"), definition
    end

    def test_nested_flow_with_optional_part_of_sequence
      create_takeaway

      order = sys.flow('order').involves sys.server

      sys.server.receives burger: { 'gimme burger' => 'here you go' }

      order.from(sys.eater) {
        order.opt('if hungry') {
          sys.server.burger
        }
      }

      definition = sequence_definition(order)

      assert_equal [
                     'opt if hungry',
                       'eater -> server: gimme burger',
                       'server -> eater: here you go',
                     'end'
                   ].join("\n"), definition
    end
    

    def test_flow_generates_precise_sequence_with_action
      order = create_food_flow

      definition = sequence_definition order

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

    def test_flow_can_be_used_to_make_connections_in_dog
      order = create_food_flow

      order.make_connections

      assert_equal('eater->server server->cook server->eater cook->server', connections)
    end

    private

    attr_accessor :sys

    def sequence_definition(order)
      order.output sequence: outfile('seq.txt')

      read_outfile('seq.txt')
    end

    def graph
      g = sys.render
      sys.output svg: outfile('svg')
      g
    end

    def create_takeaway
      @sys = System.new 'takeaway', auto_nominate: true
      eater = sys.thing 'eater'
      server = sys.thing 'server'
      cook = sys.thing 'cook'
    end
    
    def create_food_flow
      create_takeaway
      order = sys.flow 'order'
      order.flows sys.eater, 'orders',
                  sys.server, 'creates order',
                  sys.cook.does('cooks burger'),
                  'burger', sys.server,
                  'burger', sys.eater
      order
    end

  end
end