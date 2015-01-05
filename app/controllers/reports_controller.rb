class ReportsController < ComponentsController

  def index
    @components = STIXPackage.all.group_by {|i| i.package_intents.first }
    @components['Other'] = @components.delete(nil) if @components[nil]
  end

  def show
    super
  end

  def create
    error = nil
    stix = nil

    if params[:xml].content_type == 'text/xml'
      stix_xml = params[:xml].read
      begin
        stix = STIXPackage.from_xml(stix_xml)
      rescue
        error = "Unable to parse document."
      end
      if error.nil?
        begin
          stix.persist!
        rescue Exception => e
          puts e.message
          puts e.backtrace.join("\n")
          error = "Unable to persist document."
        end
      end
    else
      error = "Invalid content type."
    end

    if error
      respond_to do |format|
        format.json { render :json => {:success => false, :error => error}, :status => :unprocessable_entity}
        format.xml { render :xml => {:success => false, :error => error}, :status => :unprocessable_entity}
      end
    else
      respond_to do |format|
        format.json { render :json => {:success => true, :url => stix_path(id_string(stix.id))}}
        format.xml { render :xml => {:success => true} }
      end
    end
  end

  def klass
    STIXPackage
  end
end
