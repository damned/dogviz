module GraphChecking
  def subgraph_ids
    subgraphs.map(&:id)
  end

  def subgraph_ids_without_cluster_prefixes
    subgraph_ids.map {|id| id.gsub /^cluster_/, '' }
  end

  def subgraph(id)
    subgraphs.find {|sub| sub.id == id }
  end

  def subgraphs(from=graph)
    subs = []
    from.each_graph {|sub_name, sub|
      subs << sub
      subs += subgraphs(sub)
    }
    subs
  end

  def connections(sep=' ')
    edges.map {|e|
      "#{e.tail_node}->#{e.head_node}"
    }.join sep
  end

  def edges
    graph.each_edge
  end

  def find(name)
    graph.find_node name
  end

end
