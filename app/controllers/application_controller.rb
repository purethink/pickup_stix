class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter do
    load 'app/models/qname.rb'
    load 'app/models/campaign_type.rb'
    load 'app/models/course_of_action_type.rb'
    load 'app/models/exploit_target_type.rb'
    load 'app/models/incident_type.rb'
    load 'app/models/observable_type.rb'
    load 'app/models/stix_type.rb'
    load 'app/models/threat_actor_type.rb'
    load 'app/models/ttp_type.rb'
  end

  private

  def component_title(type)
    t(raw_component_title(type))
  end

  def components_path(type)
    send("#{type.name.underscore.gsub('_type', '').pluralize}_path")
  end
  helper_method :components_path

  def component_path(type, id)
    send("#{type.name.underscore.gsub('_type', '')}_path", id)
  end

  def translate_term(term)
    I18n.t(term, :default => humanize_term(term.to_s))
  end
  helper_method :translate_term

  def humanize_term(term)
    term.gsub(/(?<=[a-z])(?=[A-Z])/, ' ').humanize
  end

  def stix_path(id)
    "/reports/#{id}"
  end
  helper_method :stix_path

  def id_string(component)
    if component.kind_of?(Java::JavaxXmlNamespace::QName)
      id = component
    elsif component.kind_of?(String)
      return id
    else
      id = component.id
    end
    id.prefix.present? ? "#{id.prefix}:#{id.local_part}" : id.local_part
  end
  helper_method :id_string
end
