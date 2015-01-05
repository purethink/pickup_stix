class OrgMitreStixTtp::TTPType
  def display_fields
    process_display_fields([:description, :kill_chains, :intended_effects])
  end

  def top_level_structures
    [:behavior, :resources, :victim_targeting]
  end

  def self.collection_name
    self.superclass.collection_name
  end
end
