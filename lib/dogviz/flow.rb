require_relative 'sequence_renderer'
require_relative 'thing'
require_relative 'process'

module Dogviz
  class Flow
    def initialize(sys, name)
      @sys = sys
      @name = name
      @commands = []
      @actors = []
      @caller_stack = []
    end

    def make_connections
      commands.each { |type, from, to, label|
        thing_of(from).points_to(thing_of(to), label: label) if type == :call
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
      flowspec.call
      @caller_stack.pop
      @actors.each { |actor|
        actor.stop_flow
      }
    end

    def optional(text, &block)
      commands << [:opt, nil, nil, text]
      block.call
      commands << [:end, nil, nil, nil]
    end
    
    alias :opt :optional

    def add_call(from, to, label)
      commands << [:call, from, to, label]
    end

    def next_call(to, label)
      add_call @caller_stack.last, to, label
      @caller_stack << to
    end

    def end_call
      add_call @caller_stack.pop, @caller_stack.last, ''
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
      raise "Only support sequence, not: '#{type}'" unless type == :sequence
      render.output(type_to_file)
    end

    def render
      renderer = SequenceRenderer.new(@name)
      commands.each do |type, from, to, label|
        if type == :call
          renderer.render_edge(from, to, {label: label})
        elsif type == :end
          renderer.end_combination          
        else
          renderer.start_combination(type, label)
        end
      end
      renderer.rendered
    end

    private

    attr_reader :commands, :sys

    def thing_of(it)
      return it.processor if it.is_a?(Process)
      it
    end
  end
end