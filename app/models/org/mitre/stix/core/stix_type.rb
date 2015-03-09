class Java::OrgMitreStixCore::STIXType

  def self.human_name
    "report"
  end

  def package_intents
    self.stix_header.present? ? self.stix_header.package_intents.map(&:value) : []
  end

  def title
    self.stix_header.try(:title)
  end

  def description
    self.stix_header.try(:description)
  end

  def self.search(term)
    mongo_collection.find({"stix_header.title" => Regexp.new(term)}).to_a.map {|i| self.from_mongo(i)}
  end

  def display_fields
    process_display_fields([])
  end

  def information_source
    self.stix_header.try(:information_source)
  end

  def information_source=(val)
    self.stix_header ||= org.mitre.stix.core.STIXHeaderType.new
    self.stix_header.information_source = val
  end

  def handling
    self.stix_header.try(:handling)
  end

  def handling=(val)
    self.stix_header ||= org.mitre.stix.core.STIXHeaderType.new
    self.stix_header.handling = val
  end

end
