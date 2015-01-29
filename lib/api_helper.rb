class Java::OrgMitre::ApiHelper
  
  IRREGULARS = {
    'tt_ps' => 'ttps',
    'co_as' => 'coas',
    'alternative_i_ds' => 'alternative_ids',
    'external_i_ds' => 'external_ids'
  }
  
  IRREGULARS_REVERSE = Hash[IRREGULARS.to_a.reverse]
  
  SHOULD_FLATTEN = {
    org.mitre.stix.common.CampaignBaseType => org.mitre.stix.campaign.CampaignType,
    org.mitre.stix.common.CourseOfActionBaseType => org.mitre.stix.coa.CourseOfActionType,
    org.mitre.stix.common.ExploitTargetBaseType => org.mitre.stix.et.ExploitTargetType,
    org.mitre.stix.common.IncidentBaseType => org.mitre.stix.incident.IncidentType,
    org.mitre.stix.common.IndicatorBaseType => org.mitre.stix.indicator.IndicatorType,
    org.mitre.cybox.core.ObservableType => org.mitre.cybox.core.ObservableType,
    org.mitre.cybox.core.ObjectType => org.mitre.cybox.core.ObjectType,
    org.mitre.stix.core.STIXType => org.mitre.stix.core.STIXType,
    org.mitre.stix.common.ThreatActorBaseType => org.mitre.stix.ta.ThreatActorType,
    org.mitre.stix.common.TTPBaseType => org.mitre.stix.ttp.TTPType  
  }
  
  def create_placeholder(child)
    placeholder = child.class.create(:id => child.idref)
  end
  
  def subtitle
    ''
  end
  
  def build_hash(parent, handled_relationship = false)
    self.annotate_class!
    hash = {'@@class' => self.class.to_s}
    self.class.stix_fields.each do |field|
      method = field.name.underscore
      method = Java::OrgMitre::ApiHelper::IRREGULARS[method] if Java::OrgMitre::ApiHelper::IRREGULARS[method]

      child = self.send(method)

      if child.kind_of?(Array) || child.kind_of?(Java::JavaUtil::ArrayList)
        if child.length > 0
          hash[method] = (0...child.length).map {|i|
            self.handle_single_item(child[i], parent, {:field => method, :from => hash, :index => i}, handled_relationship)
          }
        end
      else
        val = self.handle_single_item(child, parent, {:field => method, :from => hash}, handled_relationship)
        hash[method] = val unless val.nil?
      end
    end
    
    if self.respond_to?(:value) && !self.value.nil?
      hash['value'] = self.handle_single_item(self.value, parent, {:field => 'value', :from => hash}, handled_relationship)
    end
    
    return hash
  end
  
  def handle_single_item(child, parent, proxy_args, handled_relationship = false)
    if child.nil?
      return nil
    elsif child.kind_of?(Java::OrgMitreStixCommon::GenericRelationshipType)
      hash = child.build_hash(parent, handled_relationship=true)
      add_full_relationship(parent, child, proxy_args[:field])
      return hash
    elsif child.kind_of?(Java::JavaxXmlNamespace::QName)
      return {
        'namespace' => child.namespace_uri,
        'local_part' => child.local_part,
        'prefix' => child.prefix
      }
    elsif should_flatten?(child)
      if child.idref.present?
        add_raw_relationship(parent, child, proxy_args[:field]) unless handled_relationship
        return {:idref => handle_single_item(child.idref, parent, {})}
      else
        child.save
        add_raw_relationship(parent, child, proxy_args[:field]) unless handled_relationship
        return {:idref => handle_single_item(child.id, parent, {})}
      end
    elsif child.respond_to?(:build_hash)
      return child.build_hash(parent)
    elsif child.respond_to?(:value)
      return child.value.to_s
    elsif child.class.to_s =~ /XMLGregorianCalendarImpl/ # Datetime stuff is annoying...
      return child.to_s
    elsif child.present?
      return child
    end        
  end
  
  def add_raw_relationship(parent, child, label)
    parent.add_relationship((SHOULD_FLATTEN[child.class] || child.class).find_or_create_node(child.id_string), label)
  end
  
  def add_full_relationship(parent, relationship, label)
    method = relationship.class.stix_fields.first.name.underscore
    method = Java::OrgMitre::ApiHelper::IRREGULARS[method] if Java::OrgMitre::ApiHelper::IRREGULARS[method]
    
    child = relationship.send(method)
    
    parent.add_relationship((SHOULD_FLATTEN[child.class] || child.class).find_or_create_node(child.id_string), label)
  end
  
  def id_string
    raise "Don't call this on things without IDs" unless self.respond_to?(:id)
    if id.present?
      "#{id.prefix}:#{id.local_part}"
    elsif idref.present?
      "#{idref.prefix}:#{idref.local_part}"
    else
      nil
    end
  end

  def should_flatten?(child)
    SHOULD_FLATTEN.keys.find {|klass| child.kind_of?(klass)}
  end  
  
  def display_fields
    process_display_fields(self.class.stix_fields.map(&:name))
  end

  def process_display_fields(fields)
    fields.select {|f| !call_by_name(f).blank?}
          .inject({}) {|coll, field| coll[field] = call_by_name(field); coll}
  end

  def call_by_name(name)
    send(IRREGULARS[name.to_s] || name.to_s.underscore)
  end
  
  def subheading
    false
  end
  
  def self.stix_fields
    own_fields = self.java_class.declared_fields
    super_fields = self.superclass.respond_to?(:stix_fields) ? self.superclass.stix_fields : []
    own_fields + super_fields
  end
  
  def self.vertex_class_name
    raise "No vertex class name set, why are you saving this in the graph!?"
  end
end