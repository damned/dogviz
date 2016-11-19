require 'ruby-graphviz'
require 'date'

module Dogviz
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
end