class Java::OrgMitreStixIncident::IncidentType

  def display_fields
    process_display_fields [:description, :time, :categories, :impact_assessment, :status, :intended_effects, :security_compromise, :discover_method]
  end

  def top_level_structures
    [:reporter, :responders, :coordinator, :victim, :affected_assets, :coa_requested, :coa_taken, :contact, :history]
  end

  def self.collection_name
    self.superclass.collection_name
  end
end
