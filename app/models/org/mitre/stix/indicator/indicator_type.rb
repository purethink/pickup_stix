class Java::OrgMitreStixIndicator::IndicatorType
  def information_source
    self.producer
  end

  def information_source=(val)
    self.producer=val
  end

  def display_fields
    process_display_fields [:description, :valid_time_position, :kill_chain_phases, :likely_impact]
  end

  def top_level_structures
    [:sightings]
  end

  def self.collection_name
    self.superclass.collection_name
  end
end
