require 'nokogiri'

module Tests
  class NamesAccessor
    def initialize(graph)
      @graph = graph
    end
    def containers
      names @graph.container_nodes
    end
    def things
      names @graph.thing_nodes
    end
    def edges
      names @graph.edge_nodes
    end

    private
    attr_reader :graph

    def names(nodes)
      nodes.map { |g|
        g.css('text').text
      }
    end
  end

  class SvgGraph
    def self.parse_file(svg_filename)
      SvgGraph.new File.read(svg_filename)
    end

    def initialize(svg)
      @doc = Nokogiri::XML(svg) {|config| config.noblanks }
    end

    def title
      title_prefix = '<!-- Title: '
      title_end = ' Pages: '
      title_node_text = comments.find { |c|
        c.to_s.start_with? title_prefix
      }.to_s
      title_node_text.gsub(title_prefix, '').split(title_end).first
    end

    def container_nodes
      @doc.css 'g.cluster'
    end

    def thing_nodes
      @doc.css 'g.node'
    end

    def edge_nodes
      @doc.css 'g.edge'
    end

    def names_of
      NamesAccessor.new self
    end

    def to_s
      @doc.to_xml indent: 2
    end

    private

    def comments
      @doc.children.select(&:comment?)
    end
  end
end