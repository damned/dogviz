require_relative 'sequence_renderer'
require_relative 'thing'
require_relative 'process'

module Dogviz
  class Flow
    FLOW_RENDERERS = {
      sequence: WebSequenceDiagramsSequenceRenderer,
      plantuml: PlantUmlSequenceRenderer,
      png: PngSequenceRenderer
    }

    attr_reader :sys
    attr_accessor :executor

    def initialize(sys, name)
      @sys = sys
      @name = name
      @commands = []
      @actors = []
      @caller_stack = []
      @executor = nil
    end

    def make_connections
      commands.each { |type, from, to, label|
        thing_of(from).points_to(thing_of(to), name: label.split('\n').first) if type == :call
      }
    end

    def involves(*actors)
      @actors += actors
      self
    end
    
    def from(initial_actor, &flowspec)
      @actors.each { |actor|
        actor.start_flow self
      }
      @caller_stack << initial_actor
      begin
        flowspec.call
      rescue NoMethodError => nme
        raise "Did you call #involves for all actors? It's a common cause of the caught exception: #{nme}"
      ensure
        @caller_stack.pop
        @actors.each { |actor|
          actor.stop_flow
        }
      end      
    end

    def add_note(from, where, what)
      # TODO yukk next lets move to command classes, e.g. OptCommand, NoteCommand, CallCommand etc.
      commands << [:note, from, where, what]
    end

    def process(process)
      commands.last[2] = process # TODO yukk again - last[2] is "other""
      @caller_stack[-1] = process
    end
    
    def optional(text, &block)
      commands << [:opt, nil, nil, text]
      block.call
      commands << [:end, nil, nil, nil]
    end

    def divider(text)
      commands << [:divider, nil, nil, text]
    end
    
    alias :opt :optional

    def add_call(from, to, label)
      commands << [:call, from, to, label]
    end

    def add_return(from, to, label)
      commands << [:return, from, to, label]
    end

    def next_call(to, label)
      add_call @caller_stack.last, to, label
      @caller_stack << to
    end

    def end_call(label)
      current_actor = @caller_stack.pop
      add_return(current_actor, @caller_stack.last, label) unless label.nil?
    end

    def flows(*steps)
      sys.warn_on_exit 'deprecation warning: flow#flows deprecated, should use flow#from(actor) { <nested flow spec> }'
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
          add_call from, to, label
          from = to
          to = label = nil
        end
      end
    end

    def ensure_is_thing(step)
      raise "Expected some thing or process: '#{step}' already got: #{commands}" unless step.is_a?(Thing) || step.is_a?(Process)
      step
    end

    def output(type_to_file)
      type = type_to_file.keys.first
      raise "Only support #{FLOW_RENDERERS.keys}, not: '#{type}'" unless FLOW_RENDERERS.has_key?(type)
      render(FLOW_RENDERERS[type]).output(type_to_file, executor)
    end

    def render(renderer_class = SequenceRenderer)
      renderer = renderer_class.new(@name, sys)
      commands.each do |type, from, to, label|
        if type == :call
          renderer.render_edge(from, to, {label: label})
        elsif type == :return
          renderer.render_return_edge(from, to, {label: label})
        elsif type == :end
          renderer.end_combination
        elsif type == :note
          renderer.note(from, to, label)
        elsif type == :divider
          renderer.divider(label)
        else
          renderer.start_combination(type, label)
        end
      end
      renderer.rendered
    end

    def suppress_messages!
      sys.suppress_messages!
    end
    
    private

    attr_reader :commands

    def thing_of(it)
      return it.processor if it.is_a?(Process)
      it
    end

  end
end