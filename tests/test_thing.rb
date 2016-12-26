require_relative 'setup_tests'
require_relative 'svg_graph'

module Tests
  class TestThing < Test::Unit::TestCase
    include Dogviz

    class StubRenderer
      attr_reader :last_node_attributes, :last_edge_options
      def render_node(parent, id, attributes)
        @last_node_attributes = attributes
      end
      def render_edge(from, other, options)
        @last_edge_options = options
      end
    end

    class StubParent
      attr_accessor :render_options
      def register(name, thing)

      end
      def colorize_edges?
        false
      end
      def rollup?
        false
      end
      def skip?
        false
      end
    end

    def setup
      @parent = StubParent.new
      @renderer = StubRenderer.new
    end

    attr_reader :parent, :renderer

    def test_thing_name_rendered_with_inherited_fontname
      parent.render_options = {fontname: 'funky-font'}

      thing = Thing.new parent, 'thing'

      thing.render renderer

      assert_equal 'funky-font', renderer.last_node_attributes[:fontname]
    end

    def test_thing_edges_rendered_with_inherited_fontname
      parent.render_options = {fontname: 'crazy-font'}

      thing = Thing.new parent, 'thing'
      thing.points_to Thing.new parent, 'other thing'

      thing.render_edges renderer

      assert_equal 'crazy-font', renderer.last_edge_options[:fontname]
    end

  end
end