class Java::OrgMitreStixCommon::IdentityType
  def display_fields
    fields = {}
    fields['Name'] = name unless name.blank?
    fields[nil] = specification if self.respond_to?(:specification)
    fields
  end
end
