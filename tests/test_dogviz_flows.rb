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
      sys = System.new 'takeaway'
      eater = sys.thing 'eater'
      server = sys.thing 'server'
      cook = sys.thing 'chef'

      order = sys.flow 'order'
      order.flows eater, 'gimme burger',
                  server, 'passes order',
                  cook, server, eater

      order.output sequence: outfile('seq.txt')

      definition = read_outfile('seq.txt')

      assert_equal [
                       'eater -> server: gimme burger',
                       'server -> chef: passes order',
                       'chef -> server:',
                       'server -> eater:',
                   ].join("\n"), definition
    end

    def create_food_flow
      @sys = System.new 'takeaway'
      eater = sys.thing 'eater'
      server = sys.thing 'server'
      cook = sys.thing 'cook'

      order = sys.flow 'order'
      order.flows eater, 'orders',
                  server, 'creates order',
                  cook.does('cooks burger'),
                  'burger', server,
                  'burger', eater
      order
    end

    def test_flow_generates_precise_sequence_with_action
      order = create_food_flow

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

    def test_flow_can_be_used_to_make_connections_in_dog
      order = create_food_flow

      order.make_connections

      assert_equal('eater->server server->cook server->eater cook->server', connections)
    end

    private

    attr_accessor :sys

    def graph
      g = sys.render
      sys.output svg: outfile('svg')
      g
    end
  end
end