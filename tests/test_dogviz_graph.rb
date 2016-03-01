require_relative 'setup_tests'

class TestDogvizGraph < Test::Unit::TestCase
  include Dogviz

  attr_reader :sys

  def setup
    @sys = Dogviz::System.new 'test'
  end

  def test_container_gets_rolled_up
    g = sys.group('g')
    assert_equal(false, g.rollup?)
    g.rollup!
    assert_equal(true, g.rollup?)
  end

  def test_stuff_isnt_under_or_on_top_of_rollup_without_rollup
    g = sys.group('g')
    a = g.thing('a')

    assert_equal(false, a.under_rollup?)
    assert_equal(false, a.on_top_rollup?)
    assert_equal(false, g.under_rollup?)
    assert_equal(false, g.on_top_rollup?)
  end

  def test_rolled_up_containers_arent_under_rollup_when_on_top
    g = sys.group('g')
    g.rollup!

    assert_equal(false, g.under_rollup?)
    assert_equal(true, g.on_top_rollup?)
  end

  def test_nested_containers_and_things_are_under_rollup
    g = sys.group('g')
    g.rollup!
    nested = g.group('nested')
    a = g.thing('a')

    assert_equal(true, nested.under_rollup?)
    assert_equal(true, a.under_rollup?)
    assert_equal(false, nested.on_top_rollup?)
  end

  def test_nested_things_are_in_rollup_if_under_one
    g = sys.group('g').rollup!
    a = g.thing('a')

    assert_equal(true, a.in_rollup?)
  end

  def test_nested_things_are_in_skip_if_under_one
    g = sys.group('g').skip!
    a = g.thing('a')

    assert_equal(true, a.in_skip?)
  end

  def test_nested_things_are_in_rollup_if_rolled_up_themselves
    a = sys.thing('a').rollup!
    assert_equal(true, a.in_rollup?)
  end

  def test_find_with_match_block
    nested_group = sys.group('g').group('nested group')
    nested_thing = nested_group.thing('nested thing')
    nested_group.thing('other thing')

    assert_equal(nested_thing, sys.find {|n|
      n.is_a?(Thing) && n.name.start_with?('nested')
    })
  end

  def test_find_all
    group = sys.group('g')
    nested_group = group.group('nested group')
    thing1 = group.thing('n1')
    thing2 = nested_group.thing('n2')

    assert_equal([thing1, thing2], sys.find_all {|n|
      n.is_a?(Thing)
    })
  end

  def test_root
    group = sys.group('g')
    nested_group = group.group('nested group')
    thing1 = group.thing('n1')

    assert_equal sys, thing1.root
  end

end