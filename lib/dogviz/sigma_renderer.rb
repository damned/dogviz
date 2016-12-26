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
      @edges << {
          id: "#{parent.id}->#{id}",
          type: 'containment',
          source: parent.id,
          target: id
      } unless parent.root?
    end

    def render_edge(from, to, options)
      @edges << {
          id: "#{from.id}->#{to.id}",
          label: "#{from.id}->#{to.id}",
          source: from.id,
          target: to.id
      }
    end

    def render_subgraph(parent, id, options, attributes)
      @nodes << {id: container_label(id), type: 'container', label: container_label(id)}
      @edges << {
          id: "#{container_label parent.id}->#{container_label id}",
          type: 'containment',
          source: container_label(parent.id),
          target: container_label(id)
      } unless parent.root?
    end

    private

    def container_label(id)
      id
    end

    attr_reader :nodes, :edges
  end
end
