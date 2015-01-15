class OrgMitreStixTtp::TTPType
  def display_fields
    process_display_fields([:description, :kill_chains, :intended_effects])
  end

  def top_level_structures
    (behavior_structures + resources_structures + victim_targeting_structures).compact
  end

  def behavior_structures
    return [] if behavior.nil?
    vals = []
    if behavior.malware.try(:malware_instances)
      vals += behavior.malware.malware_instances.map {|i| [:malware, i]}
    end
    if behavior.attack_patterns.try(:attack_patterns)
      vals += behavior.attack_patterns.attack_patterns.map {|i| [:attack_pattern, i]}
    end
    if behavior.exploits.try(:exploits)
      vals += behavior.exploits.exploits.map {|i| [:exploit, i]}
    end
    return vals
  end

  def resources_structures
    return [] if resources.nil?
    resources.process_tls(:tools) + resources.process_tls(:infrastructure) + resources.process_tls(:personas)
  end

  def victim_targeting_structures
    victim_targeting.nil? ? [] : [[:victim_targeting, victim_targeting]]
  end

  def self.collection_name
    self.superclass.collection_name
  end
end
