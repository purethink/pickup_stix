class Java::OrgMitreStixCore::STIXType

  def self.name
    "Report"
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
end
