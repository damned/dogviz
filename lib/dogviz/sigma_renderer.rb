require_relative 'sigma_graph_hash'

module Dogviz
  class SigmaRenderer
    def initialize(title)
      @title = title
      @nodes = []
      @edges = []
    end

    def graph
      SigmaGraphHash.new(nodes: nodes, edges: edges)
    end

    def render_node(parent, id, render_options, attributes)
      @nodes << {id: id, label: id}
    end

    def render_edge(from, to, options)
      @edges << {
          id: "#{from.id}->#{to.id}",
          label: "#{from.id}->#{to.id}",
          source: from.id,
          target: to.id
      }
    end

    private

    attr_reader :nodes, :edges
  end
end