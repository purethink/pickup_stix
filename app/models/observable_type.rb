class Java::OrgMitreCyboxCore::ObservableType

  def display_fields
    process_display_fields [:description]
  end

  def top_level_structures
    process_basic_tls([:object, :event])
  end
end
