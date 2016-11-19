require_relative 'parent'
require_relative 'nominator'
require_relative 'registry'

module Dogviz
  class System
    include Parent
    include Nominator

    attr_reader :render_hints, :title, :children, :graph

    alias :name :title
    alias :render_options :render_hints

    def initialize(name, hints = {splines: 'line'})
      @children = []
      @by_name = Registry.new name
      @non_render_hints = remove_dogviz_hints!(hints)
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
      renderer = create_renderer(type)

      children.each { |c|
        c.render renderer
      }
      children.each { |c|
        c.render_edges renderer
      }
      @rendered = true
      @graph = renderer.graph
    end

    def create_renderer(type)
      if type == :graphviz
        GraphvizRenderer.new @title, render_hints
      elsif type == :sigma
        SigmaRenderer.new @title
      else
        raise "dunno bout that '#{type}', only know :graphviz or :sigma"
      end

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

    def colorize_edges?
      @non_render_hints[:colorize_edges]
    end

    private

    def remove_dogviz_hints!(hints)
      dogviz_only_hints = {}
      %i(colorize_edges).each { |k|
        dogviz_only_hints[k] = hints.delete k
      }
      dogviz_only_hints
    end

    def create_title(name)
      now = DateTime.now
      "#{now.strftime '%H:%M'} #{name} #{now.strftime '%F'}"
    end

    def run_from_command_line?
      $stdout.isatty
    end
  end
end