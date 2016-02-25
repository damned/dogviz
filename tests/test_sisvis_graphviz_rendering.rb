require "test/unit"

require_relative '../lib/sisvis'

class TestSisvisGraphvizRendering < Test::Unit::TestCase
  include Sisvis

  attr_reader :sys

  def setup
    @sys = Sisvis::System.new 'test'
  end

  def graph
    sys.render
  end

  def test_points_to_links_nodes
    sys.thing('a').points_to sys.thing('b')

    assert_equal('a->b', connections)
  end

  def test_points_to_all_makes_multiple_links_to_nodes
    sys.thing('a').points_to_all sys.thing('b'), sys.thing('c')

    assert_equal(2, edges.size)
    assert_equal(find('a').id, edges[0].tail_node)
    assert_equal(find('b').id, edges[0].head_node)
    assert_equal(find('a').id, edges[1].tail_node)
    assert_equal(find('c').id, edges[1].head_node)
    assert_equal('a->b a->c', connections)
  end

  def test_containers_are_subgraphs_prefixed_with_cluster_for_visual_containment_in_GraphViz
    top = sys.container('top')
    nested = top.container('nested')

    assert_equal('cluster_top', subgraph_ids.first)
    assert_equal('cluster_top_nested', subgraph_ids.last)
  end

  def test_logical_containers_have_no_cluster_prefix_so_will_not_be_visible_in_Graphviz
    top = sys.logical_container('top')
    top_thing = top.thing('top thing')

    assert_equal(['top'], subgraph_ids)
    assert_equal(top_thing.id, subgraph('top').get_node("#{top_thing.id}").id)
  end

  def test_nested_containers_have_things
    top = sys.container('top')
    top_thing = top.thing('top thing')
    nested = top.container('nested')
    nested_thing = nested.thing('nested thing')

    graph

    assert_equal([top.render_id, nested.render_id], subgraph_ids)

    top_subgraph = subgraph(top.render_id)
    nested_subgraph = subgraph(nested.render_id)

    assert_equal(top_thing.id, top_subgraph.get_node(top_thing.id).id)
    assert_equal(nested_thing.id, nested_subgraph.get_node(nested_thing.id).id)
    assert_nil(top_subgraph.get_node(nested_thing.id), 'should not be in other container')
    assert_nil(nested_subgraph.get_node(top_thing.id), 'should not be in other container')
  end

  def test_point_into_target_in_container
    container = sys.container('container')
    target = container.thing('target')
    pointer = sys.thing('pointer')

    pointer.points_to target

    assert_equal("pointer->#{target.id}", connections)
  end

  def test_node_names_are_displayed
    thing = sys.container('whatever').thing('the thing')
    assert_equal('whatever_the_thing', thing.id)
    assert_equal('"the thing"', find(thing.id)[:label].to_s)
  end

  def test_point_into_target_in_nested_containers
    top = sys.container('top')
    target_parent = top.container('nested').container('subnested')
    target = target_parent.thing('target')
    pointer = sys.thing('pointer')

    pointer.points_to target

    assert_equal('pointer->top_nested_subnested_target', connections)
  end

  def test_points_to_rolled_up_container_of_target
    group = sys.container('group')
    group.rollup!
    target = group.thing('target')
    pointer = sys.thing('pointer')

    pointer.points_to target

    assert_equal('pointer->group', connections)
  end

  def test_points_from_thing_in_rolled_up_container
    group = sys.group('group')
    group.rollup!

    pointer = group.thing('pointer')
    target = sys.thing('target')

    pointer.points_to target

    assert_equal('group->target', connections)
  end

  def test_points_to_rolled_up_nested_containers_of_target
    top = sys.container('top', rollup: false)
    nested = top.container('nested', rollup: true)
    target = nested.container('subnested').thing('target')
    pointer = sys.thing('pointer')

    top.thing('thing in top')
    nested.thing('thing in nested')

    pointer.points_to target

    assert_equal('pointer->top_nested', connections)
    assert_not_nil(graph.find_node('top_thing_in_top'))
  end

  def test_points_to_multiple_things_in_rolled_up_group
    group = sys.group('group', rollup: true)
    pointer = sys.thing('pointer')

    pointer.points_to_all group.thing('a'), group.thing('b'), group.thing('c')

    assert_equal('pointer->group', connections)
  end

  def test_pointing_from_rolled_up_thing_in_non_rolled_up_group_creates_no_links
    a = sys.thing('a', rollup: true)
    b = sys.thing('b')
    c = sys.thing('c')
    a.points_to b
    b.points_to c
    assert_equal('b->c', connections)
  end

  def test_find_thing
    sys.group('top').thing('needle')

    assert_equal('needle', sys.find('needle').name)
  end

  def test_find_duplicate_show_blow_up
    sys.group('A').thing('needle')
    sys.group('B').thing('needle')

    assert_raise DuplicateLookupError do
      sys.find('needle').name
    end
  end

  def test_find_nothing_show_blow_up
    sys.group('A').thing('needle')

    assert_raise LookupError do
      sys.find('not a needle')
    end
  end

  def test_doclinks_create_links
    a = sys.thing('a')
    doc_url = 'http://some.url/'
    a.doclink doc_url

    assert_equal(doc_url, find('a')['URL'].to_ruby)
  end

  private

  def subgraph_ids
    subgraphs.map(&:id)
  end

  def subgraph(id)
    subgraphs.find {|sub| sub.id == id }
  end

  def subgraphs(from=graph)
    subs = []
    from.each_graph {|sub_name, sub|
      subs << sub
      subs += subgraphs(sub)
    }
    subs
  end

  def connections(sep=' ')
    edges.map {|e|
      "#{e.tail_node}->#{e.head_node}"
    }.join sep
  end

  def connected_ids
    (edges.map(&:tail_node) + edges.map(&:head_node)).uniq
  end

  def edges
    graph.each_edge
  end

  def find(name)
    graph.find_node name
  end

end