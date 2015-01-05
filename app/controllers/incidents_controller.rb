class IncidentsController < ComponentsController

  def index
    @components = Incident.all.group_by {|i| i.status.try(&:value) }
    @components['Unknown Status'] = @components.delete(nil) if @components[nil]
  end

  def klass
    Incident
  end
end
