module ApplicationHelper
  BLACKLIST = ['id', 'timestampPrecision', 'cyboxMajorVersion', 'cyboxMinorVersion', 'cyboxUpdateVersion']
  def render_generic_template(obj, label = nil, heading_level = 2)
    return '' if obj.blank? || obj.nil?
    Rails.logger.info "Rendering: #{label}, #{obj.inspect}"
    if obj.respond_to?(:dereference_error?)
      render('/shared/dereference_error', :item => obj)
    elsif obj.respond_to?(:each)
      Rails.logger.info("INFO: Rendering generic list for: #{label}, #{obj.to_a.inspect}")
      render('/shared/generic_list', :items => obj, :lbl => label.to_s.try(&:singularize), :heading_level => heading_level)
    elsif obj.respond_to?(:java_class) && File.exists?("app/views/#{class_path(obj)}")
      render partial(obj), :object => obj, :lbl => label, :heading_level => heading_level
    elsif obj.kind_of?(org.mitre.cybox.common.BaseObjectPropertyType) || obj.kind_of?(org.mitre.cybox.common.ControlledVocabularyStringType)
      render 'org/mitre/cybox/common/base_object_property_type', :object => obj, :lbl => label, :heading_level => heading_level
    elsif obj.class.respond_to?(:stix_fields)
      if obj.respond_to?(:idref) && obj.idref.present?
        newobj = obj.dereference

        obj = newobj unless newobj.nil?
      end

      if obj.class.stix_fields.length == 1
        field = obj.class.stix_fields.first.name
        render_generic_template(obj.send(field), label, heading_level)
      else
        Rails.logger.warn("WARN: Rendering generic section for #{obj.class.to_s}, #{label}")
        render('/shared/generic_section', :object => obj, :lbl => label, :heading_level => heading_level)
      end
    elsif !BLACKLIST.include?(label)
      Rails.logger.warn("WARN: Rendering generic field for #{obj.class.to_s}, #{label}")
      render('/shared/generic_field', :object => obj, :lbl => label, :heading_level => heading_level)
    end
  end

  def class_path(obj)
    obj.java_class.package.name.gsub('.','/') + '/_' + obj.class.name.underscore + ".html.erb"
  end

  def partial(obj)
    obj.class.java_class.package.name.gsub('.','/') + '/' + obj.class.name.underscore
  end
end
