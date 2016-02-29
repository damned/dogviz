require_relative 'setup_tests'

class TestDogvizFunctionally < Test::Unit::TestCase

  def svg_outfile
    '/tmp/dogviz_functional_test.svg'
  end

  def setup
    File.delete svg_outfile if File.exist?(svg_outfile)
  end

  include Dogviz
  def test_outputs_svg_graph

    sys = System.new 'family'

    house = sys.container 'household'

    cat = house.thing 'cat'
    dog = house.thing 'dog'

    mum = house.thing 'mum'
    son = house.thing 'son'

    mum.points_to son, name: 'parents'
    son.points_to mum, name: 'respects'

    cat.points_to dog, name: 'chases'
    dog.points_to son, name: 'follows'

    sys.output svg: svg_outfile

    svg_content = File.read svg_outfile

    assert_includes svg_content, 'family'
  end
end