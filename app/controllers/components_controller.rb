class ComponentsController < ApplicationController

  before_filter { @active_component = klass }

  def index
    @components = klass.all
  end

  def stix
    p = STIXPackage.new
    p.stix_header = org.mitre.stix.core.STIXHeaderType.new
    p.stix_header.title = "Export from pickup-stix"
    @component = klass.find(params[:id])

    p.send("add_#{@component.class.name.split('::').last.gsub('Type', '').underscore}", @component)

    render :xml => p.to_xml
  end

  def show
    stix and return if request.format == :xml

    @component = klass.find(params[:id])
    raise "Component not found: #{params[:id]}" if @component.nil?
    @out = @component.relationships(:outgoing)
    @out = Hash[@out.reject {|k,v| blacklisted_relationship?(k, :out)}.sort_by {|k, v| v.length}]
    puts "Mapped"
    @in = @component.relationships(:incoming)
    @in = Hash[@in.reject {|k,v| blacklisted_relationship?(k, :in)}.sort_by {|k, v| v.length}]
  end

  def find_connections
    @component = klass.find(params[:id])

    respond_to do |format|
      format.html
      format.json {
        render :json => find_connections_to(params[:target])
      }
    end
  end

  private
  def blacklisted_relationship?(rel, dir)
    false
  end

  def find_connections_to(target)
    target_object = target['class'].constantize.find(target['id'])

    sp_query = "MATCH (source {stix_id:\"#{@component.id_string}\"}),(target {stix_id:\"#{target_object.id_string}\"}),p=allShortestPaths((source)-[*]-(target)) RETURN nodes(p) as nodes,relationships(p) as relationships"

    results = Neo4j::Session.query(sp_query).to_a

    nodes = []
    relationships = []
    map = {}

    results.each do |path|
      path['nodes'].each_with_index do |n, i|
        if map[n.neo_id].nil?
          nodes << {title: n['title'], type: n['class'], id: n.neo_id}
          map[n.neo_id] = nodes.length - 1
        end
      end

      path['relationships'].each do |r|
        relationships << {source: map[r.start_node.neo_id], target: map[r.end_node.neo_id]}
      end
    end

    return {
      graph: {
        nodes: nodes,
        edges: relationships
      }
    }
  end
end
