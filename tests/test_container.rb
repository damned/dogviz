require_relative 'setup_tests'
require_relative 'svg_graph'

module Tests
  class TestContainer < Test::Unit::TestCase
    include Dogviz

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
    end

    attr_reader :parent

    def test_container_exposes_inherited_render_options_from_parent
      inheritable_options = {fontname: 'glyphoz'}
      parent.render_options = inheritable_options
      assert_equal 'glyphoz', Container.new(parent, 'container').render_options[:fontname]
    end
  end
end