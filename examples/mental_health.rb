require 'dogviz'

all = Dogviz::System.new 'mental health', splines: true

all.thing('me')
    .points_to(all.thing('signs'), name: 'look for')
    .points_to(all.thing('actions'), name: 'validate')
    .points_to(all.thing('factors'), name: 'change')
    .points_to(all.find('me'), name: 'affect')

all.output svg: 'mental_health-generated.svg'
