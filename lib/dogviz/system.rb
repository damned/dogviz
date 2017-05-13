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
      
      @warnings = Set.new
      @messages = Set.new
      
      @suppress_warnings = false
      @suppress_messages = false
      
      on_exit {
        output_messages
        output_warnings
      }
    end

    def output(*args)
      render
      out = graph.output(*args)
      @messages << "Created output: #{args.join ' '}" unless suppress_messages?
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

    def auto_nominate?
      @non_render_hints[:auto_nominate]
    end
    
    def warn_on_exit(warning)
      @warnings << warning
    end

    def warnings
      @warnings.to_a
    end
    
    def messages
      @messages.to_a
    end
    
    def suppress_warnings!
      @suppress_warnings = true
      self
    end
    
    def suppress_messages!
      @suppress_messages = true
      self
    end

    private

    def on_exit(&block)
      Kernel.at_exit(&block)
    end

    def output_messages
      unless suppress_messages?
        messages.each {|message|
          STDERR.puts message
        }
      end
    end
    
    def output_warnings
      unless suppress_warnings?
        warnings.each {|warning|
          STDERR.puts warning
        }
      end
    end

    def suppress_warnings?
      @suppress_warnings
    end

    def suppress_messages?
      @suppress_messages
    end

    def remove_dogviz_hints!(hints)
      dogviz_only_hints = {}
      %i(colorize_edges auto_nominate).each { |k|
        dogviz_only_hints[k] = hints.delete k
      }
      dogviz_only_hints
    end

    def create_title(name)
      now = DateTime.now
      "#{now.strftime '%H:%M'} #{name} #{now.strftime '%F'}"
    end
  end
end