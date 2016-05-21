# dogviz
domain object graph visualisation built on graphviz

bundle install

bundle exec ruby examples/dogfood.rb

![generated graph from examples/dogfood.rb](/examples/dogviz-generated.jpg)

```ruby
require 'dogviz'

def create_classes_description(root)
  classes = root.container('classes')
  system = classes.thing('System')
  thing = classes.thing('Thing')
  container = classes.thing('Container')
  container.points_to thing, name: 'contains'
  container.points_to container, name: 'contains'
  system.points_to thing, name: 'contains'
  system.points_to container, name: 'contains'
end

def create_nested_container_example(root, name:)
  example = root.container name
  thing = example.thing 'a thing outside a container'
  container = example.container 'a container'
  container_thing = container.thing 'a thing in a container'
  nested_container = container.container 'a nested container'
  nested_c_thing = nested_container.thing 'a thing in a nested container'

  container_thing.points_to nested_c_thing
  nested_c_thing.points_to thing, name: 'things point to other things'

  nested_container
end

domain_object_graph = Dogviz::System.new 'dogviz'

create_classes_description(domain_object_graph)
usage = domain_object_graph.group('usage')

create_nested_container_example(usage, name: 'example DOG')
create_nested_container_example(usage, name: '...with a rolled up container').rollup!

domain_object_graph.output svg: 'examples/dogviz-generated.svg'
domain_object_graph.output jpg: 'examples/dogviz-generated.jpg'
```


