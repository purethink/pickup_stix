class Java::OrgMitreStixTa::ThreatActorType
  def display_fields
    process_display_fields([:sophistications, :types, :motivations, :intended_effects, :planning_and_operational_supports])
  end

  def top_level_structures
    process_basic_tls([:identity])
  end

  def self.collection_name
    self.superclass.collection_name
  end
end
