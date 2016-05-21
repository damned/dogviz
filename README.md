# dogviz
A domain object graph (**DOG**) visualisation built initially on graphviz

## Features

## Usage

bundle install

bundle exec ruby examples/dogfood.rb

## Example

Here is the diagram rendered by running the [dogfood example](examples/dogfood.rb)

![generated graph from examples/dogfood.rb](/examples/dogviz-generated.jpg "Generated diagram")

Use the simple DSL to build your domain graph of *things* which can be in *containers*, which in turn can be nested.

*Things* can point to other *things*.

Because this is ruby you can use known refactorings for **DOG** construction: extract methods, push into classes etc.

No external DSL rubbish here! ;)

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

  classes
end

def create_nested_container_example(root)
  example = root.container 'example DOG'
  thing = example.thing 'a thing outside a container'
  container = example.container 'a container'
  container_thing = container.thing 'a thing in a container'
  nested_container = container.container 'a nested container'
  nested_c_thing = nested_container.thing 'a thing in a nested container'

  container_thing.points_to nested_c_thing
  nested_c_thing.points_to thing, name: 'things point to other things'

  nested_container
end

def create_dog(classes: true)
  domain_object_graph = Dogviz::System.new 'dogviz'

  create_classes_description(domain_object_graph) if classes
  usage = domain_object_graph.group('usage')

  create_nested_container_example(usage)

  domain_object_graph
end

create_dog().output svg: 'examples/dogviz-generated.svg'
create_dog().output jpg: 'examples/dogviz-generated.jpg'

dog_rolled_up = create_dog(classes: false)
dog_rolled_up.find('a nested container').rollup!
dog_rolled_up.output jpg: 'examples/dogviz-rolled-up-generated.jpg'
```

## Rolling up

You can **rollup!** *containers* before rendering so that a single **DOG** can be used to render simplified views.

The following output from above example shows how diagram can be simplified by *rolling up* the nested container.
Note that pointers to/from contained things are handled gracefully ([i think](https://github.com/damned/dogviz/blob/master/tests/test_dogviz_graphviz_rendering.rb#L97) :/).

![generated rolled up graph from examples/dogfood.rb](/examples/dogviz-rolled-up-generated.jpg "Generated rolled up diagram")



