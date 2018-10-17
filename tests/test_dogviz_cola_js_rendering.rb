require_relative 'setup_tests'

class TestDogvizColaJsRendering < Test::Unit::TestCase
  include Dogviz

  attr_reader :sys

  def setup
    @sys = Dogviz::System.new 'test'
  end

  def test_renders_empty_graph__as_cola_js_graph_definition
    graph = sys.render(:cola)

    assert_equal({ nodes: [], links: [], groups: [] }, graph)
  end

  # example from: https://ialab.it.monash.edu/webcola/examples/smallgroups.html
  expected_cola_json = {
    "nodes":[
      {"name": "a", "width": 60, "height":40},
      {"name": "b", "width": 60, "height":40},
      {"name": "c", "width": 60, "height":40},
      {"name": "d", "width": 60, "height":40},
      {"name": "e", "width": 60, "height":40},
      {"name": "f", "width": 60, "height":40},
      {"name": "g", "width": 60, "height":40}
    ],
    "links":[
      {"source": 1,"target": 2},
      {"source": 2,"target": 3},
      {"source": 3,"target": 4},
      {"source": 0,"target": 1},
      {"source": 2,"target": 0},
      {"source": 3,"target": 5},
      {"source": 0,"target": 5}
    ],
	"groups":[
	  {"leaves":[0], "groups":[1]},
	  {"leaves":[1,2]},
	  {"leaves":[3,4]}
	]
}

  def test_renders_single_node__as_cola_js_graph_definition
    sys.thing('a')

    graph = sys.render(:cola)

    assert_equal({nodes: [ { name: 'a', width: 60, height: 40 }], links: [], groups: []}, graph)
  end

  def xtest_includes_containers_with_appropriate_types
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

  def xtest_outputs_to_json
    outfile = '/tmp/cola_test.json'
    FileUtils.rm_f outfile

    empty_graph = sys.render(:json)
    empty_graph.output json: outfile

    #xxxxxxx
    assert_equal('{"nodes":[],"edges":[]}', File.read(outfile))
  end

  def xtest_output_requires_type
    assert_raise_message(/provide hash/) {
      sys.render(:cola).output 'file'
    }
  end

  def xtest_json_only_output
    assert_raise_message(/json.*only/) {
      sys.render(:cola).output xml: 'xmlfile'
    }
  end

end
