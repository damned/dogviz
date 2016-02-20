require "test/unit"

require_relative '../lib/sisvis'

class TestSisvis < Test::Unit::TestCase
  include Sisvis

  attr_reader :sys

  def setup
    @sys = Sisvis::System.new 'test'
  end

  def graph
    sys.graph
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
    top_thing = top.thing('top thing')
    nested = top.container('nested')
    nested_thing = nested.thing('nested thing')

    assert_equal('cluster_top', subgraph_ids.first)
  end

  def test_nested_containers_have_things
    top = sys.container('top')
    top_thing = top.thing('top thing')
    nested = top.container('nested')
    nested_thing = nested.thing('nested thing')

    assert_equal([top.rendered_id, nested.rendered_id], subgraph_ids)

    top_subgraph = subgraph(top.rendered_id)
    nested_subgraph = subgraph(nested.rendered_id)

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

  def test_points_to_rolled_up_nested_containers_of_target
    top = sys.container('top')
    nested = top.container('nested')
    nested.rollup!
    target = nested.container('subnested').thing('target')
    pointer = sys.thing('pointer')

    top.thing('thing in top')
    nested.thing('thing in nested')

    pointer.points_to target

    assert_equal('pointer->top_nested', connections)
    assert_not_nil(graph.find_node('top_thing_in_top'))
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