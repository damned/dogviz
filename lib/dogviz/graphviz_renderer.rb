require 'ruby-graphviz'
require 'date'

module Dogviz
  class GraphvizRenderer
    attr_reader :graph

    def initialize(title, hints)
      construction_hints = {}
      after_hints = hints.clone
      if hints.has_key?(:use)
        construction_hints[:use] = hints[:use]
        after_hints.delete :use
      end
      @graph = GraphViz.digraph(title, construction_hints)
      @graph[after_hints]
      @subgraphs = {}
      @nodes = {}
      @rendered_subgraph_ids = {}
    end

    def render_edge(from, other, options)
      edge = graph.add_edges from.id, other.id
      options.each { |key, value|
        edge[key] = value unless value.nil?
      }
      edge
    end

    def render_node(parent, id, attributes, node)
      clean_node_attributes attributes
      default_attributes = {:shape => 'box', :style => ''}
      merged_attributes = default_attributes.merge(attributes)
      parent_node(parent).add_nodes(id, merged_attributes)
    end

    def render_subgraph(parent, id, attributes)
      if (attributes[:bounded] == true) then
        rendered_id = 'cluster_' + id
      else
        rendered_id = id
      end
      @rendered_subgraph_ids[id] = rendered_id

      subgraph = parent_node(parent).add_graph(rendered_id, clean_subgraph_attributes(attributes.clone))
      @subgraphs[id] = subgraph
      subgraph
    end

    private

    def clean_node_attributes(attributes)
      attributes.delete(:rank)
      attributes.delete(:bounded)
      attributes
    end

    def clean_subgraph_attributes(attributes)
      attributes.delete(:bounded)
      attributes
    end

    def parent_node(parent)
      return graph if parent.root?
      node = graph.search_node(parent.id)
      return node unless node.nil?
      subgraph = @subgraphs[parent.id]
      raise "couldn't find node or graph: #{parent.id}, out of graphs: #{graph_ids}" if subgraph.nil?
      subgraph
    end

    def apply_render_attributes(node, attributes)
      attributes.each do |key, value|
        node[key] = value
      end
    end
  end
end