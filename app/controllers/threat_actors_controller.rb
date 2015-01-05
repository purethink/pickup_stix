class ThreatActorsController < ComponentsController

  def index
    @components = ThreatActor.all.group_by {|t|
      t.types.map(&:value).map {|v| v.try(&:value)}.first
    }
    @components['Other'] = @components.delete(nil) if @components[nil]
  end

  def klass
    ThreatActor
  end
end
