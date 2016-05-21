require_relative '../lib/dogviz'

def factors(parent)
  factors = parent.container('factors')
  parent.nominate factors: factors
  all = factors.thing('factors')

  makeup = all.points_to factors.thing 'make-up'
  history = all.points_to factors.thing 'history'
  situation = all.points_to factors.thing 'situation'

  patterns = makeup.points_to factors.thing 'patterns'
  makeup.points_to factors.thing 'genetic'
  makeup.points_to(factors.thing 'childhood').points_to patterns, name: 'forms'

  history.points_to(factors.thing 'background').points_to patterns, name: 'forms, reinforces'
  history.points_to(factors.thing 'recent').points_to patterns, name: 'reinforces'

  situation.points_to factors.thing 'health'
  situation.points_to factors.thing 'pressures'
  support = situation.points_to factors.thing('support')

  support.points_to factors.thing 'friends'
  support.points_to factors.thing 'family'
  support.points_to factors.thing 'colleagues'

  all
end

def description
  all = Dogviz::System.new 'mental health', splines: true
  all.thing('me')
      .points_to(all.thing('signs'), name: 'look for')
      .points_to(all.thing('actions'), name: 'validate')
      .points_to(factors(all), name: 'change')
      .points_to(all.find('me'), name: 'affect')
  all
end

description.output svg: 'mental-health-generated.svg'

simplified = description
simplified.factors.rollup!
simplified.output svg: 'mental-health-simplified-generated.svg'
