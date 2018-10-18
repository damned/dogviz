require_relative 'cola_graph_hash'

module Dogviz
  class ColaRenderer
    def initialize(title)
      @title = title
      @nodes = []
      @links = []
      @groups = []
    end

    def graph
      ColaGraphHash.new(nodes: nodes, links: links, groups: groups)
    end

    def render_node(parent, id, attributes, node)
      @nodes << {name: node.name, width: 60, height: 40}
      # @links << {
      #     id: "#{parent.id}->#{id}",
      #     type: 'containment',
      #     source: parent.id,
      #     target: id
      # } unless parent.root?
    end

    # def render_edge(from, to, options)
    #   @edges << {
    #       id: "#{from.id}->#{to.id}",
    #       label: "#{from.id}->#{to.id}",
    #       source: from.id,
    #       target: to.id
    #   }
    # end

    def render_subgraph(parent, id, attributes)
      @groups << {leaves: [0]}
    end

    # private

    # def container_label(id)
    #   id
    # end

    attr_reader :nodes, :links, :groups
  end
end
