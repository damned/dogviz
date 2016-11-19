require_relative 'sequence_renderer'
require_relative 'thing'
require_relative 'process'

module Dogviz
  class Flow
    def initialize(sys, name)
      @sys = sys
      @name = name
      @calls = []
    end

    def make_connections
      calls.each { |from, to, label|
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
end