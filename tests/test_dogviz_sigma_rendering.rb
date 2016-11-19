require_relative 'setup_tests'

class TestDogvizSigmaRendering < Test::Unit::TestCase
  include Dogviz

  attr_reader :sys

  def setup
    @sys = Dogviz::System.new 'test'
  end

  def test_renders_empty_graph__as_sigma_js_graph_definition
    graph = sys.render(:sigma)

    assert_equal({ nodes: [], edges: [] }, graph)
  end

  def test_renders_single_node__as_sigma_js_graph_definition
    sys.thing('a')

    graph = sys.render(:sigma)

    assert_equal({nodes: [ { id: 'a', label: 'a' }], edges: []}, graph)
  end

  def test_renders_two_linked_nodes
    sys.thing('a').points_to sys.thing('b')

    graph = sys.render(:sigma)

    assert_equal({nodes: [
        { id: 'a', label: 'a' },
        { id: 'b', label: 'b' }
    ], edges: [
        {
            id: 'a->b',
            label: 'a->b',
            source: 'a',
            target: 'b'
        }
    ]}, graph)

    graph.output json: '/tmp/simpls.json'
  end

  def test_outputs_to_json
    outfile = '/tmp/sigma_test.json'
    FileUtils.rm_f outfile

    empty_graph = sys.render(:sigma)
    empty_graph.output json: outfile

    assert_equal('{"nodes":[],"edges":[]}', File.read(outfile))
  end

  def test_output_requires_type
    assert_raise_with_message(StandardError, /provide hash/) {
      sys.render(:sigma).output 'file'
    }
  end

  def test_json_only_output
    assert_raise_with_message(StandardError, /json.*only/) {
      sys.render(:sigma).output xml: 'xmlfile'
    }
  end

end