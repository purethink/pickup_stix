class CampaignsController < ComponentsController

  def index
    @components = Campaign.all.group_by {|c| c.status.try(&:value) }
    @components['Unknown Status'] = @components.delete(nil) if @components[nil]
  end

  def klass
    Campaign
  end
end
