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
    @component = klass.find(params[:id])
    @out = @component.relationships(:outgoing)
    @out = Hash[@out.reject {|k,v| blacklisted_relationship?(k, :out)}.sort_by {|k, v| v.length}]
    @in = @component.relationships(:incoming)
    @in = Hash[@in.reject {|k,v| blacklisted_relationship?(k, :in)}.sort_by {|k, v| v.length}]
    raise "Component not found: #{params[:id]}" if @component.nil?
  end

  private
  def blacklisted_relationship?(rel, dir)
    false
  end
end
