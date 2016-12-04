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

  def test_includes_containers_with_appropriate_types
    sys.container('c').thing('a')

    graph = sys.render(:sigma)

    assert_equal({
                     nodes: [
                         { id: 'c', type: 'container', label: 'c' },
                         { id: 'c_a', label: 'c_a' }
                     ],
                     edges: [
                         {
                             id: 'c->c_a',
                             type: 'containment',
                             source: 'c',
                             target: 'c_a'
                         }
                     ]
                 }, graph)
  end

  def test_includes_nested_containers_modelled_with_containment_edges
    sys.container('c').container('cc').thing('x')

    graph = sys.render(:sigma)

    assert_equal({
                     nodes: [
                         { id: 'c', type: 'container', label: 'c' },
                         { id: 'c_cc', type: 'container', label: 'c_cc' },
                         { id: 'c_cc_x', label: 'c_cc_x' }
                     ],
                     edges: [
                         {
                             id: 'c->c_cc',
                             type: 'containment',
                             source: 'c',
                             target: 'c_cc'
                         },
                         {
                             id: 'c_cc->c_cc_x',
                             type: 'containment',
                             source: 'c_cc',
                             target: 'c_cc_x'
                         }
                     ]
                 }, graph)
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
