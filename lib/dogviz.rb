require 'ruby-graphviz'

module Dogviz
  class Process
    def initialize(processor, description)
      @processor = processor
      @description = description
    end
    def name
      @processor.name
    end
    def description
      @description
    end
    attr_reader :processor
  end
  module Flowable
    def does(action)
      Process.new(self, action)
    end
  end
  module Nominator
    def nominate(names_to_nominees)
      names_to_nominees.each {|name, nominee|
        self.class.send(:define_method, name) do
          nominee
        end
      }
    end
    def nominate_from(nominee_nominator, *nominee_names)
      nominee_names.each {|name|
        accessor_sym = name.to_s.to_sym
        nominate accessor_sym => nominee_nominator.send(accessor_sym)
      }
    end
  end
  module Common
    def create_id(name, parent)
      parts = []
      parts << parent.id if parent.respond_to? :id
      parts += name.split /\s/
      parts.join '_'
    end
    def root
      ancestors.last
    end
    def ancestors
      ancestors = [parent]
      loop do
        break unless ancestors.last.respond_to?(:parent)
        ancestors << ancestors.last.parent
      end
      ancestors
    end
    def info(fields)
      @info.merge! fields
      setup_render_attributes(label: label_with_info)
    end
    def doclink(url)
      setup_render_attributes(URL: url)
    end
    def label_with_info
      lines = [ name ]
      @info.each {|k, v|
        lines << "#{k}: #{v}"
      }
      lines.join "\n"
    end
    def setup_render_attributes(attributes)
      @attributes = {} if @attributes.nil?
      @attributes.merge!(attributes)
    end
    def rollup?
      @rollup
    end
    def rollup!
      @rollup = true
      self
    end
    def skip!
      @skip = true
      self
    end

    def skip?
      @skip
    end

    def in_skip?
      skip? || under_skip?
    end

    def under_skip?
      ancestors.any? &:skip?
    end

    def under_rollup?
      ancestors.any? &:rollup?
    end
    def in_rollup?
      rollup? || under_rollup?
    end
    def on_top_rollup?
      rollup? && !under_rollup?
    end
  end
  module Parent
    def find_all(&matcher)
      raise MissingMatchBlockError.new unless block_given?
      @by_name.find_all &matcher
    end
    def find(name=nil, &matcher)
      if block_given?
        @by_name.find &matcher
      else
        raise 'Need to provide name or block' if name.nil?
        @by_name.lookup name
      end
    end
    def thing(name, options={})
      add Thing.new self, name, options
    end
    def container(name, options={})
      add Container.new self, name, options
    end
    def logical_container(name, options={})
      add LogicalContainer.new self, name, options
    end
    def group(name, options={})
      logical_container name, options
    end
    def add(child)
      @children << child
      child
    end
  end

  class Thing
    include Common
    include Nominator
    include Flowable
    attr_reader :parent
    attr_reader :name, :id, :pointers, :edge_heads

    def initialize(parent, name, options = {})
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      @pointers = []
      @rollup = false
      @skip = false
      @info = {}
      @edge_heads = []

      rollup! if options[:rollup]
      options.delete(:rollup)

      @render_options = options
      setup_render_attributes label: name

      parent.register name, self
    end

    def do_render_node(renderer)
      render_options = @render_options
      attributes = @attributes
      renderer.render_node(parent, id, render_options, attributes)
    end

    def points_to_all(*others)
      others.each {|other|
        points_to other
      }
    end

    def points_to(other, options = {})
      setup_render_edge(other, options)
      other
    end

    def render(renderer)
      do_render_node(renderer) unless in_rollup? || in_skip?
    end

    def render_edges(renderer)
      pointers.each {|p|
        render_pointer p, renderer
      }
    end

    private

    def setup_render_edge(other, options)
      pointers << {
          other: other,
          options: {
              label: options[:name],
              style: options[:style]
          }
      }
    end

    def render_pointer(pointer, renderer)
      other = pointer[:other]
      while (other.in_rollup? && !other.on_top_rollup?) do
        other = other.parent
      end
      return if other.under_rollup?

      from = self
      while (from.in_rollup? && !from.on_top_rollup?) do
        from = from.parent
      end

      return if from.in_skip?

      return if from == self && from.in_rollup?
      return if from == other
      return if already_added_connection?(other)

      if other.in_skip?
        others = resolve_skipped_others other
      else
        others = [other]
      end

      others.each do |other|
        edge_heads << other
        render_options = pointer[:options]
        renderer.render_edge(from, other, render_options)
      end
    end

    def already_added_connection?(other)
      edge_heads.include? other
    end

    def resolve_skipped_others(skipped)
      resolved = []
      skipped.pointers.each {|pointer|
        next_in_line = pointer[:other]
        if next_in_line.in_skip?
          resolved += resolve_skipped_others next_in_line
        else
          resolved << next_in_line
        end
      }
      resolved
    end
  end

  class Container
    include Common
    include Nominator
    include Parent
    attr_reader :parent
    attr_reader :name, :id, :node, :render_id, :render_type, :render_options, :children

    def initialize(parent, name, options = {})
      @children = []
      @by_name = Registry.new name
      @parent = parent
      @name = name
      @id = create_id(name, parent)
      @skip = false
      @info = {}

      init_rollup options

      setup_render_attributes label: name

      @render_options = options

      parent.register name, self
    end

    def register(name, thing)
      @by_name.register name, thing
      parent.register name, thing
    end

    def render(renderer)
      if on_top_rollup?
        do_render_node renderer
      elsif !under_rollup?
        do_render_subgraph renderer
      end

      children.each {|c|
        c.render renderer
      }
    end

    def render_edges(renderer)
      children.each {|c|
        c.render_edges renderer
      }
    end

    private

    def do_render_subgraph(renderer)
      @render_type = :subgraph
      render_id = cluster_prefix + id
      attributes = @attributes
      @render_id = render_id
      @subgraph = renderer.render_subgraph(parent, render_id, render_options, attributes)
    end

    def do_render_node(renderer)
      @render_type = :node
      @render_id = id
      render_id = @render_id
      attributes = @attributes
      renderer.render_node(parent, render_id, render_options, attributes)
    end

    def init_rollup(options)
      @rollup = false
      rollup! if options[:rollup]
      options.delete(:rollup)
    end

    def cluster_prefix
      is_cluster = true
      if @render_options.has_key? :cluster
        is_cluster = @render_options[:cluster]
        @render_options.delete :cluster
      end
      cluster_prefix = (is_cluster ? 'cluster_' : '')
    end

  end

  class LogicalContainer < Container
    def initialize(parent, name, options)
      super parent, name, options.merge(cluster: false)
    end
  end

  require 'date'

  class GraphvizRenderer
    attr_reader :graph

    def initialize(title, hints)
      @graph = GraphViz.digraph(title)
      @graph[hints]
      @subgraphs = {}
      @nodes = {}
    end

    def render_edge(from, other, options)
      edge = graph.add_edges from.id, other.id
      options.each { |key, value|
        edge[key] = value unless value.nil?
      }
      edge
    end

    def render_node(parent, id, options, attributes)
      clean_node_options options
      default_options = {:shape => 'box', :style => ''}
      node = parent_node(parent).add_nodes(id, default_options.merge(options))
      apply_render_attributes node, attributes
    end

    def render_subgraph(parent, id, options, attributes)
      subgraph = parent_node(parent).add_graph(id, options)
      apply_render_attributes subgraph, attributes
      @subgraphs[id] = subgraph
      subgraph
    end

    private

    def clean_node_options(options)
      options.delete(:rank)
      options.delete(:cluster)
      options
    end

    def parent_node(parent)
      return graph unless parent.respond_to?(:render_id)
      node = graph.search_node(parent.render_id)
      return node unless node.nil?
      subgraph = @subgraphs[parent.render_id]
      raise "couldn't find node or graph: #{parent.render_id}, out of graphs: #{graph_ids}" if subgraph.nil?
      subgraph
    end

    def apply_render_attributes(node, attributes)
      attributes.each do |key, value|
        node[key] = value
      end
    end
  end

  class Flow
    def initialize(sys, name)
      @sys = sys
      @name = name
      @calls = []
    end

    def make_connections
      calls.each {|from, to, label|
        thing_of(from).points_to thing_of(to), label: label
      }
    end

    def flows(*steps)
      from = nil
      to = nil
      label = nil
      steps.each do |step|
        if from.nil?
          from = ensure_is_thing(step)
        elsif label.nil? && step.is_a?(String)
          label = step
        elsif to.nil?
          to = ensure_is_thing(step)
        end
        unless to.nil?
          calls << [from, to, label]
          from = to
          to = label = nil
        end
      end
    end

    def ensure_is_thing(step)
      raise "Expected some thing or process: '#{step}' already got: #{calls}" unless step.is_a?(Thing) || step.is_a?(Process)
      step
    end

    def output(type_to_file)
      type = type_to_file.keys.first
      raise "Only support sequence, not: '#{type}'" unless type == :sequence
      render.output(type_to_file)
    end

    def render
      renderer = SequenceRenderer.new(@name)
      calls.each do |from, to, label|
        renderer.render_edge from, to, {label: label}
      end
      renderer.rendered
    end

    private

    attr_reader :calls, :sys

    def thing_of(it)
      return it.processor if it.is_a?(Process)
      it
    end
  end


  class RenderedSequence
    def initialize(lines)
      @lines = lines
    end
    def output(type_to_file)
      text = @lines.map(&:strip).join "\n"
      File.write type_to_file.values.first, text
      text
    end
  end

  class SequenceRenderer
    attr_reader :lines
    def initialize(title)
      @lines = []
    end

    def render_edge(from, other, options)

      detail = options[:label]
      receiver_label = other.name
      sender_label = from.name
      if other.is_a?(Process)
        detail = process_annotations(detail, sender_label, receiver_label, other.description)
        receiver_label = process_start_label(receiver_label)
      elsif from.is_a?(Process)
        receiver_label = process_end_label(receiver_label)
      end
      lines << "#{sender_label} -> #{receiver_label}: #{detail}"
    end

    def rendered
      RenderedSequence.new lines
    end

    private

    def process_start_label(receiver_label)
      "+#{receiver_label}"
    end

    def process_end_label(receiver_label)
      "-#{receiver_label}"
    end

    def process_annotations(detail, sender, receiver, process_description)
      detail = [detail,
                "note right of #{receiver}",
                "  #{process_description}",
                'end note'].join("\n")
    end
  end

  class System
    include Parent

    attr_reader :render_hints, :title, :children, :graph

    alias :name :title

    def initialize(name, hints = {splines: 'line'})
      @children = []
      @by_name = Registry.new name
      @render_hints = hints
      @title = create_title(name)
      @rendered = false
    end

    def output(*args)
      render
      out = graph.output *args
      puts "Created output: #{args.join ' '}" if run_from_command_line?
      out
    end

    def flow(name)
      Flow.new self, name
    end

    def render(type=:graphviz)
      return @graph if @rendered
      raise "dunno bout that '#{type}', only know :graphviz" unless type == :graphviz

      renderer = GraphvizRenderer.new @title, render_hints

      children.each {|c|
        c.render renderer
      }
      children.each {|c|
        c.render_edges renderer
      }
      @rendered = true
      @graph = renderer.graph
    end

    def rollup?
      false
    end

    def skip?
      false
    end

    def register(name, thing)
      @by_name.register name, thing
    end

    private

    def create_title(name)
      now = DateTime.now
      "#{now.strftime '%H:%M'} #{name} #{now.strftime '%F'}"
    end

    def run_from_command_line?
      !ARGV.empty?
    end
  end

  class LookupError < StandardError
    def initialize(context, message)
      super "(in context '#{context}') #{message}"
    end
  end
  class MissingMatchBlockError < LookupError
    def initialize(context)
      super context, 'need to provide match block'
    end
  end
  class DuplicateLookupError < LookupError
    def initialize(context, name)
      super context, "More than one object registered of name '#{name}' - you'll need to search in a narrower context"
    end
  end
  class Registry
    def initialize(context)
      @context = context
      @by_name = {}
      @all = []
    end

    def register(name, thing)
      @all << thing
      if @by_name.has_key?(name)
        @by_name[name] = DuplicateLookupError.new @context, name
      else
        @by_name[name] = thing
      end
    end

    def find(&matcher)
      raise LookupError.new(@context, "need to provide match block") unless block_given?
      @all.find &matcher
    end

    def find_all(&matcher)
      raise MissingMatchBlockError.new(@context) unless block_given?
      @all.select &matcher
    end

    def lookup(name)
      found = @by_name[name]
      raise LookupError.new(@context, "could not find '#{name}'") if found.nil?
      raise found if found.is_a?(Exception)
      found
    end
  end

end
