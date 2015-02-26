class Java::OrgMitreStixTtp::TTPType
  def display_fields
    process_display_fields([:description, :kill_chains, :intended_effects])
  end

  def top_level_structures
    structs = []
    structs << {:label => 'Victim Targeting', :object => victim_targeting} if victim_targeting.present?

    if behavior.present?
      if malware = behavior.malware
        malware.malware_instances.each do |mi|
          structs << {:label => 'Malware', :object => mi}
        end
      end

      (behavior.attack_patterns.try(&:attack_patterns) || []).each do |ap|
        structs << {:label => 'Attack Pattern', :object => ap}
      end

      (behavior.exploits.try(&:exploits) || []).each do |e|
        structs << {:label => 'Exploit', :object => e}
      end
    end

    if resources.present?
      (resources.tools.try(&:tools) || []).each do |tool|
        structs << {:label => 'Tool', :object => tool}
      end

      (resources.personas.try(&:personas) || []).each do |p|
        structs << {:label => 'Persona', :object => p}
      end

      if resources.infrastructure
        structs << {:label => "Infrastructure", :object => resources.infrastructure}
      end
    end

    return structs
  end

  def self.collection_name
    self.superclass.collection_name
  end
end

class Java::OrgMitreStixTtp::MalwareType
  def display_fields
    fields = {}
    malware_instances
  end
end
