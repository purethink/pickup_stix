class Java::OrgMitreStixIndicator::IndicatorType
  def display_fields
    process_display_fields [:description, :valid_time_position, :kill_chain_phases, :likely_impact]
  end

  def top_level_structures
    process_basic_tls([:sightings])
  end

  def self.collection_name
    self.superclass.collection_name
  end
end
