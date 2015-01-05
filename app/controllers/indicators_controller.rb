class IndicatorsController < ComponentsController

  def index
    @components = Indicator.all.group_by {|i| i.types.map(&:value).join(", ") }
    @components['Unknown Type'] = @components.delete('') if @components['']
  end

  def klass
    Indicator
  end

  def blacklisted_relationship?(rel, dir)
    rel == 'indicated_ttps' || (rel == 'indicators') || rel == 'observable'
  end
end
