class Java::OrgMitreStixCoa::CourseOfActionType

  def display_fields
    process_display_fields [:description, :stage, :type, :objective, :impact, :cost, :efficacy]
  end

  def top_level_structures
    [:parameter_observables, :structured_coa]
  end

  def self.collection_name
    self.superclass.collection_name
  end
end
