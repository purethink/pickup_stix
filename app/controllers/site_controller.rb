class SiteController < ApplicationController

  COMPONENTS = [
    STIXPackage, Indicator, TTP, Observable, Incident,
    Campaign, ThreatActor, CourseOfAction, ExploitTarget
  ]

  def dashboard
    @statistics = COMPONENTS.map do |component|
      {
        count: component.count,
        type: component,
        name: component.name,
        link: components_path(component)
      }
    end
  end

  def autocomplete
    @term = params[:term]

    results = (COMPONENT_TYPES.values + [STIXPackage]).map do |type|
      type.search(@term)
    end.flatten

    respond_to do |format|
      format.json { render :json => results.map {|r| {
        :title => r.title,
        :type => r.class.name.split('::').last.gsub('Type', '').downcase,
        :url => component_path(r.class, id_string(r))
      }}}
    end
  end
end
