require_relative 'setup_tests'
require_relative 'graph_checking'

module Tests
  class TestDogvizFlows < Test::Unit::TestCase
    include GraphChecking

    def outfile(ext)
      "/tmp/dogviz_flow_test.#{ext}"
    end

    def delete_outfile(ext)
      FileUtils.rm_f outfile(ext)
    end

    def read_outfile(ext)
      File.read outfile(ext)
    end

    include Dogviz

    def test_nested_flow_syntax
      create_takeaway

      order = sys.flow('order').involves(sys.server, sys.cook)

      sys.server.receives burger: { 'gimme burger' => 'here ya go' }, 
                          dessert: 'gimme dessert'
      sys.cook.receives order: { 'passes order' => '' }

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
                    'eater -> server: gimme dessert'
                  ].join("\n"), definition
    end

    def test_get_useful_error_if_not_called_involves_for_called_actor
      create_takeaway

      order = sys.flow('order')

      sys.server.receives burger: 'gimme burger'

      assert_raise_message(/call #involves for all actors/) {

        order.from(sys.eater) {
          sys.server.burger
        }
        
      }
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
                     'opt "if hungry"',
                     '  eater -> server: gimme burger',
                     '  server -> eater: here you go',
                     'end'
                   ].join("\n"), definition
    end

    def test_nested_flow_dynamic_receives_definition
      create_takeaway

      order = sys.flow('order').involves sys.server

      sys.server.receives(:order) do |order_no| 
        { "make order #{order_no}" => "deliver order #{order_no}" }
      end

      order.from(sys.eater) {
        sys.server.order(1)
        sys.server.order(2)
      }

      definition = sequence_definition(order)

      assert_equal [
                     'eater -> server: make order 1',
                     'server -> eater: deliver order 1',
                     'eater -> server: make order 2',
                     'server -> eater: deliver order 2'
                   ].join("\n"), definition
    end

    def test_plantuml_text_output
      create_takeaway

      order = sys.flow('the order').involves sys.server

      sys.server.receives burger: 'gimme'

      order.from(sys.eater) {
        sys.server.burger
      }

      order.output plantuml: outfile('seq.plantuml')
      definition = read_outfile('seq.plantuml')

      assert_equal [
                     '@startuml',
                     'title the order',
                     'eater -> server: gimme',
                     '@enduml'
                   ].join("\n"), definition
    end

    def test_plantuml_dividers
      create_takeaway

      order = sys.flow('order')

      sys.server.receives burger: 'gimme'

      order.from(sys.eater) {
        order.divider('bob')
      }

      definition = order.output plantuml: outfile('seq.plantuml')

      assert_equal [
                     '@startuml',
                     'title order',
                     '== bob ==',
                     '@enduml'
                   ].join("\n"), definition
    end
    
    
    class MockExecutor
      def execute(cmd)
        @cmd = cmd
      end
      attr_reader :cmd
    end
    

    def test_flow_png_image_output_via_plantuml
      create_takeaway

      order = sys.flow('order').involves sys.server

      sys.server.receives burger: 'gimme'

      order.from(sys.eater) {
        sys.server.burger
      }

      plantuml_definition_file = outfile('seq.plantuml')
      FileUtils.rm_f plantuml_definition_file
      mock_executor = MockExecutor.new
      order.executor = mock_executor
      order.output png: outfile('seq.png')
      
      assert_equal true, File.exist?(plantuml_definition_file)
      assert_equal 'plantuml -tpng ' + plantuml_definition_file, mock_executor.cmd
    end
    
    def test_nested_flow_with_note_on_right
      create_takeaway

      order = sys.flow('order').involves sys.server, sys.eater

      sys.server.receives burger: 'gimme burger'

      order.from(sys.eater) {
        sys.server.burger
        sys.server.note(:right, 'a note')
      }

      definition = sequence_definition(order)

      assert_equal [
                     'eater -> server: gimme burger',
                     'note right of server',
                     '  a note',
                     'end note',
                   ].join("\n"), definition
    end

    def test_nested_flow_generates_sequence_with_process_activation
      create_takeaway

      grill = sys.thing 'grill'
      order = sys.flow('order').involves sys.server, sys.cook, grill

      sys.server.receives burger: { 'gimme burger' => 'here ya go' }, 
                          dessert: 'gimme dessert'
      sys.cook.receives order: { 'passes order' => 'burger' }
      grill.receives turn_on: { 'turn on' => 'on' }

      order.from(sys.eater) {
        sys.server.burger {
          sys.cook.order {
            sys.cook.does 'cooks burger' # or maybe should be tied in at #receives definition?
            grill.turn_on
          }
        }
        sys.server.dessert
      }

      definition = sequence_definition(order)

      assert_equal [
                    'eater -> server: gimme burger',
                    'server -> +cook: passes order',
                    'note right of cook',
                    '  "cooks burger"',
                    'end note',
                    'cook -> grill: turn on',
                    'grill -> cook: on',
                    'cook -> -server: burger',
                    'server -> eater: here ya go',
                    'eater -> server: gimme dessert'
                  ].join("\n"), definition
    end

    def test_flow_generates_precise_sequence_with_deprecated_flows
      create_takeaway
      sys.suppress_warnings!

      order = sys.flow 'order'
      order.flows sys.eater, 'gimme burger',
                  sys.server, 'passes order',
                  sys.cook, sys.server, sys.eater

      definition = sequence_definition(order, without_lines_starting: [])

      assert_equal [
                     'title order',
                     'eater -> server: gimme burger',
                     'server -> cook: passes order',
                     'cook -> server:',
                     'server -> eater:',
                   ].join("\n"), definition
    end

    def test_flow_can_be_used_to_make_connections_in_dog_with_deprecated_flows
      order = create_food_flow_with_deprecated_flows

      order.make_connections

      assert_equal('eater->server server->cook server->eater cook->server', connections)
    end

    def test_deprecated_flows_generates_warnings
      order = create_food_flow_with_deprecated_flows

      assert_equal(1, order.sys.warnings.select {|w| w.include?('flow#flows deprecated')}.size)
    end

    private

    attr_accessor :sys

    def sequence_definition(order, without_lines_starting: ['title'])
      order.output sequence: outfile('seq.txt')

      lines = read_outfile('seq.txt').split "\n"
      without_lines_starting.each {|prefix|
        lines = lines.reject {|line| line.start_with?(prefix) }
      }
      lines.join "\n"
    end

    def graph
      g = sys.render
      sys.output svg: outfile('svg')
      g
    end

    def create_takeaway
      @sys = System.new('takeaway', auto_nominate: true).suppress_messages!
      sys.thing 'eater'
      sys.thing 'server'
      sys.thing 'cook'
    end
    
    def create_food_flow_with_deprecated_flows
      create_takeaway
      order = sys.flow 'order'
      sys.suppress_warnings!
      order.flows sys.eater, 'orders',
                  sys.server, 'creates order',
                  sys.cook.does('cooks burger'),
                  'burger', sys.server,
                  'burger', sys.eater
      order
    end

  end
end