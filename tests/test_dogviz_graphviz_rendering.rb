require_relative 'setup_tests'
require_relative 'graph_checking'

class TestDogvizGraphvizRendering < Test::Unit::TestCase
  include Dogviz
  include GraphChecking

  attr_reader :sys

  def setup
    @sys = Dogviz::System.new 'test'
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

  def test_do_not_render_rolled_up_thing
    sys.thing('a').rollup!

    assert_nil(find('a'))
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

  def test_point_to_between_and_from_things_in_rolled_up_container
    entry = sys.thing('entry')
    group = sys.group('group')
    a = group.thing('a')
    b = group.thing('b')
    exit = sys.thing('exit')
    entry.points_to a
    a.points_to b
    b.points_to exit

    group.rollup!

    assert_equal('entry->group group->exit', connections)
  end

  def test_skip_one_thing_with_one_onward_connection
    a = sys.thing('a')
    b = sys.thing('b')
    c = sys.thing('c')

    a.points_to b
    b.points_to c

    b.skip!

    assert_equal('a->c', connections)
  end

  def test_skip_one_thing_with_multiple_onward_connections
    a = sys.thing('a')
    b = sys.thing('b')
    out1 = sys.thing('out1')
    out2 = sys.thing('out2')

    a.points_to b
    b.points_to_all out1, out2

    b.skip!

    assert_equal('a->out1 a->out2', connections)
  end

  def test_skip_one_thing_with_multiple_inward_connections
    in1 = sys.thing('in1')
    in2 = sys.thing('in2')
    skipper = sys.thing('skipper')
    out = sys.thing('out')

    in1.points_to skipper
    in2.points_to skipper
    skipper.points_to out

    skipper.skip!

    assert_equal('in1->out in2->out', connections)
  end

  def test_skip_one_thing_with_multiple_inward_and_outward_connections
    in1 = sys.thing('in1')
    in2 = sys.thing('in2')
    skipper = sys.thing('skipper')
    out1 = sys.thing('out1')
    out2 = sys.thing('out2')

    in1.points_to skipper
    in2.points_to skipper
    skipper.points_to out1
    skipper.points_to out2

    skipper.skip!

    assert_equal('in1->out1 in1->out2 in2->out1 in2->out2', connections)
  end

  def test_skip_multiple_things_with_one_onward_connection
    start = sys.thing('start')
    skip1 = sys.thing('skip1')
    skip2 = sys.thing('skip2')
    skip3 = sys.thing('skip3')
    finish = sys.thing('finish')

    start.points_to(skip1).points_to(skip2).points_to(skip3).points_to finish

    skip1.skip!
    skip2.skip!
    skip3.skip!

    assert_equal('start->finish', connections)
  end

  def test_skip_multiple_things_with_multiple_onward_connections
    start = sys.thing('start')
    skip1 = sys.thing('skip1')
    skip2 = sys.thing('skip2')
    skip3 = sys.thing('skip3')
    skipX = sys.thing('skip_x')
    skipY = sys.thing('skip_y')
    finish1 = sys.thing('finish1')
    finish2 = sys.thing('finish2')

    start.points_to(skip1).points_to(skip2)
      skip2.points_to(skip3).points_to(skipX).points_to finish1
      skip2.points_to(skipY).points_to finish2

    skip1.skip!
    skip2.skip!
    skip3.skip!
    skipX.skip!
    skipY.skip!

    assert_equal('start->finish1 start->finish2', connections)
  end

  def test_skip_thing_in_skipped_container
    start = sys.thing('start')
    g = sys.group('g')
    a = g.thing('a')
    finish = sys.thing('finish')

    start.points_to(a).points_to(finish)

    g.skip!

    assert_equal('start->finish', connections)
  end

  def test_skip_things_in_multiple_skipped_containers
    start = sys.thing('start')
    g1 = sys.group('g1')
    a1 = g1.thing('a1')
    g2 = sys.group('g2')
    a2 = g2.thing('a2')

    finish = sys.thing('finish')

    start.points_to(a1).points_to(a2).points_to(finish)

    g1.skip!
    g2.skip!

    assert_equal('start->finish', connections)
  end

  def test_skipped_thing_will_not_be_rendered
    sys.thing('a').skip!

    assert_nil find('a')
  end

  def test_skipped_group_of_things_will_not_be_rendered
    g = sys.group('g').skip!
    g.thing('a')
    g.thing('b')

    assert_nil find('g_a')
    assert_nil find('g_b')
  end


  def test_doclinks_create_links
    a = sys.thing('a')
    doc_url = 'http://some.url/'
    a.doclink doc_url

    assert_equal(doc_url, find('a')['URL'].to_ruby)
  end

  def test_info_rendered_into_label
    a = sys.thing('a')
    a.info(ip: '1.1.1.1')

    assert_equal('a', a.name)
    assert_equal('"a\nip: 1.1.1.1"', find('a')['label'].to_ruby)
  end

  def test_nominate_reduces_need_to_find_when_piecing_together_chunks_built_in_other_methods
    def build_haystack
      haystack = sys.group 'haystack'
      needle = haystack.group('nested').group('hidden away').thing('needle')

      haystack.nominate needle: needle
      haystack
    end

    haystack = build_haystack

    thread = sys.thing 'thread'
    thread.points_to haystack.needle

    assert_equal('thread->haystack_nested_hidden_away_needle', connections)
  end

end