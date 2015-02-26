class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :authorize!

  def self.klass
    'generic'
  end

  def klass
    'generic'
  end

  private

  def component_title(type)
    t(raw_component_title(type))
  end

  def components_path(type)
    send("#{type.human_name.pluralize}_path")
  end
  helper_method :components_path

  def component_path(type, id)
    send("#{type.human_name}_path", id)
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

  def authorize!
    redirect_to signin_path unless current_user
  end

  def current_user
    @current_user ||= User.where(:_id => session[:user_id]['$oid']).first if session[:user_id]
  end
  helper_method :current_user

  # Render a not found error
  def not_found(message = "Not Found")
    raise ActionController::RoutingError.new(message)
  end
end
