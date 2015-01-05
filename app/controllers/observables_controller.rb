class ObservablesController < ComponentsController

  def index
    @components = Observable.all.group_by {|o|
      if o.object.present?
        component_title(o.object.properties.class)
      else
        'Event'
      end
    }
  end

  def klass
    Observable
  end
end
