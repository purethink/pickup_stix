class Java::OrgMitreStixCampaign::CampaignType

  def display_fields
    process_display_fields([:description, :names, :intended_effects, :status])
  end

  def self.collection_name
    self.superclass.collection_name
  end
end
