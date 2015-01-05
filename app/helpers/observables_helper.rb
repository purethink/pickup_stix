module ObservablesHelper
  def render_observable(observable)
    if observable.object.present?
      render "/objects/show", :object => observable.object.dereference
    elsif observable.observable_composition.present?
      render "/observables/composition", :observable => observable
    else
      "Unsupported"
    end
  end

  def observable_type(observable)
    if observable.object.present?
      component_title(observable.object.dereference.properties.class).gsub(" Type", "").html_safe
    else
      "Composition"
    end
  end
end
