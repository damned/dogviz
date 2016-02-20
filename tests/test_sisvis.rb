require "test/unit"
require_relative '../sisvis'

class TestSisvis < Test::Unit::TestCase
  include Sisvis

  attr_reader :sys

  def setup
    @sys = Sisvis::System.new 'test'
  end

  def graph
    sys.graph
  end

  def test_links_nodes
    sys.thing('a').points_to sys.thing('b')

    a = graph.find_node('a')
    b = graph.find_node('b')

    edges = graph.each_edge
    assert_equal(1, edges.size)
    assert_equal(a.id, edges.first.tail_node)
    assert_equal(b.id, edges.first.head_node)
  end
end