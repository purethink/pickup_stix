class ComponentsController < ApplicationController

  before_filter { @active_component = klass }

  def index
    @components = klass.all
  end

  def show
    @component = klass.find(params[:id])
    @out = @component.relationships(:out)
    @out = Hash[@out.reject {|k,v| blacklisted_relationship?(k, :out)}.sort_by {|k, v| v.length}]
    @in = @component.relationships(:in)
    @in = Hash[@in.reject {|k,v| blacklisted_relationship?(k, :in)}.sort_by {|k, v| v.length}]
    raise "Component not found: #{params[:id]}" if @component.nil?
  end

  private
  def blacklisted_relationship?(rel, dir)
    false
  end
end
