class TTPsController < ComponentsController

  def index
    @components = TTP.all.group_by {|ttp|
      m = ttp.behavior.try(&:malware).present?
      ap = ttp.behavior.try(&:attack_patterns).present?
      e = ttp.behavior.try(&:exploits).present?
      r = ttp.resources.present?
      vt = ttp.victim_targeting.present?

      if m && !ap && !e && !r && !vt
        'Malware'
      elsif !m && ap && !e && !r && !vt
        'Attack Pattern'
      elsif !m && !ap && e && !r && !vt
        'Exploit'
      elsif !m && !ap && !e && r && !vt
        'Resource'
      elsif !m && !ap && !e && !r && vt
        'Victim Targeting'
      else
        'Unknown'
      end
    }
  end

  def klass
    TTP
  end
end
