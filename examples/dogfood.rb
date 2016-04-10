require 'dogviz'

dogviz = Dogviz::System.new 'dogviz', splines: true

classes = dogviz.container('classes')
system = classes.thing('System')
thing = classes.thing('Thing')
container = classes.thing('Container')
container.points_to thing, name: 'contains'
container.points_to container, name: 'contains'
system.points_to thing, name: 'contains'
system.points_to container, name: 'contains'


dogviz.output svg: 'dogviz-generated.svg'
