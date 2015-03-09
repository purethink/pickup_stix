class Java::OrgMitreCyboxCore::ObservableType

  def display_fields
    process_display_fields [:description]
  end

  def top_level_structures
    [:object, :event]
  end

  def information_source
    nil
  end

  def information_source=(val)
    nil
  end

  def handling
    nil
  end

  def handling=(val)
    nil
  end
end
