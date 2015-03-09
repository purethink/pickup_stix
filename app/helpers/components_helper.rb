module ComponentsHelper
  def component_title(type)
    t(raw_component_title(type))
  end

  def raw_component_title(type)
    type.to_s.split("::").last
  end

  def component_type_name(component)
    raw_component_title(component.class).downcase.gsub("type","")
  end

  def component_instance_title(component)
    component.title || "(Untitled #{component_title(component.class)})".html_safe
  end

  def component_path(component, args={})
    send("#{component.class.human_name}_path", id_string(component.id || component.idref), args)
  end

  def component_path_for_class(id, klass)
    send("#{klass.split('::').last.underscore.split('/').last.gsub('_type', '').gsub('_base', '')}_path", id)
  end

  def component_color(type, postfix="color")
    type = type.name if type.respond_to?(:name)
    type = type.split('::').last
    "#{type.gsub('Type', '').downcase}-#{postfix}"
  end

  def top_level_structures(component)
    component.respond_to?(:top_level_structures) ? component.top_level_structures : false
  end

  def normalize_list(object)
    object.respond_to?(:each) ? object.map {|obj| normalize_list(obj)}.flatten : object.send(object.class.stix_fields.first.name)
  end

  def field_name(field)
    field.name.to_s.underscore
  end

  def info_source_items(information_source)
    information_source.contributing_sources.sources.collect do |cs|
      cs.roles.map(&:value).join(", ") + ": " + cs.identity.name
    end
  end

  def handling_items(handling)
    handling.markings.map do |marking|
      marking.marking_structures.map do |ms|
        if ms.kind_of?(org.mitre.data_marking.extensions.markingstructure.TermsOfUseMarkingStructureType)
          ms.terms_of_use
        end
      end
    end.flatten
  end

end
