class IndicatorsController < ComponentsController

  def index
    @components = Indicator.all.group_by {|i| i.types.map(&:value).join(", ") }
    @components['Unknown Type'] = @components.delete('') if @components['']
  end
  
  def show
    super
  end

  def klass
    Indicator
  end

  def blacklisted_relationship?(rel, dir)
    rel == 'indicators' || rel == 'observable'
  end
end
