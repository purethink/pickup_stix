class Java::OrgMitreCyboxCore::ObservableType

  def display_fields
    process_display_fields [:description]
  end
  
  def top_level_structures
    [:object, :event]
  end
end
