module Serializer

  attr_accessor :neo_node, :parent, :mongo_document

  SHOULD_DEREF = {
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

  IRREGULARS = {
    'externalIDs' => 'external_ids'
  }

  SHOULD_DEREF.keys.each do |derefable|
    not_found = Class.new(derefable) do
      def initialize(parent)
        super(idref: parent.idref, timestamp: parent.timestamp)
      end

      def dereference_error?
        true
      end
    end

    derefable.const_set("ReferenceNotAvailable", not_found)
  end

  def self.included(klass)
    klass.send(:extend, Serializer::ClassMethods)
  end

  def persist!
    verify_id!

    # See if anything exists already
    if me = self.class.find(self.id.to_s)
      return me
    else
      @neo_node = add_neo_node(self.class, id_string(self.id))
      flatten_relationships!
      json = JSON.parse(self.to_json)
      @mongo_document = mongo_collection.insert(json)
    end

    return self
  end

  def dereference
    if self.id.present?
      @target ||= self
    elsif self.idref.present?
      puts self.dereference_class.inspect
      @target ||= self.dereference_class.find(self.idref.to_s)
    end

    return @target || self.class::ReferenceNotAvailable.new(self)
  end

  def dereference_class

    SHOULD_DEREF[self.class] || self.class
  end

  def relationships(direction = nil)
    if direction.present?
      relationships = $neography.get_node_relationships(neo_node, direction)
    else
      relationships = $neography.get_node_relationships(neo_node)
    end
    relationships.inject({}) do |coll, obj|
      if obj['data']['real']
        coll[obj['type']] ||= []
        if obj['end'].split('/').last == neo_node.neo_id
          coll[obj['type']] << Neography::Node.load(obj['start'])
        else
          coll[obj['type']] << Neography::Node.load(obj['end'])
        end
      end
      coll
    end
  end

  def neo_node
    if self.respond_to?(:id) && self.id.present?
      @neo_node ||= add_neo_node(self.class, id_string(self.id))
    else
      @parent_node ||= parent.neo_node
    end
  end

  def id_string(id)
    "#{id.prefix}:#{id.local_part}"
  end

  def add_neo_node(klass, id)
    node = Neography::Node.find("node_id_index", "id", id, $neography) rescue nil

    if node.nil?
      node = Neography::Node.create({"id" => id}, $neography)
      node.title = self.title if self.respond_to?(:title) && self.title.present?
      $neography.set_label node, DEFAULT_IMPLEMENTATIONS[klass].try(:to_s) || klass.to_s
      node.add_to_index("node_id_index", "id", id)
    else
      node.title = self.title if self.respond_to?(:title) && self.title.present?
    end

    return node
  end

  def add_neo_relationship(from, to, descriptor, real = false)
    $neography.create_relationship(descriptor, from, to, 'real' => real)
  end

  def top_level_node?
    TOP_LEVEL_TYPES.include?(self.class)
  end

  def flatten_relationships!(parent_label = '')
    self.annotate_class!
    self.class.stix_fields.each do |field|
      method = field.name.underscore
      method = "ttps"            if method == "tt_ps"
      method = "coas"            if method == "co_as"
      method = "alternative_ids" if method == "alternative_i_ds"
      child = self.send(method)

      child.parent = self if child.respond_to?(:parent)

      if child && child.respond_to?(:idref) && should_deref?(child)
        if child.idref.present?
          node = add_neo_node(child.class, id_string(child.idref))

          if parent_label.include?(method)
            add_neo_relationship(self.neo_node, node, parent_label, child.top_level_node?)
          else
            add_neo_relationship(self.neo_node, node, method, child.top_level_node?)
          end
        else
          child.persist!

          if parent_label.include?(method)
            add_neo_relationship(self.neo_node, child.neo_node, parent_label, child.top_level_node?)
          else
            add_neo_relationship(self.neo_node, child.neo_node, method, child.top_level_node?)
          end

          self.send("#{method}=", child.class.new(:idref => child.id))
          child.parent = self
        end
      elsif child.kind_of?(Array) || child.kind_of?(Java::JavaUtil::ArrayList)
        (0...child.length).each do |i|
          child[i].parent = self if child[i].respond_to?(:parent)
          if child[i].respond_to?(:idref) && should_deref?(child[i])
            if child[i].idref.present?
              node = add_neo_node(child[i].class, id_string(child[i].idref))
              if parent_label.include?(method)
                add_neo_relationship(self.neo_node, node, parent_label, child[i].top_level_node?)
              else
                add_neo_relationship(self.neo_node, node, method, child[i].top_level_node?)
              end
            else
              child[i].persist!
              if parent_label.include?(method)
                add_neo_relationship(self.neo_node, child[i].neo_node, parent_label, child[i].top_level_node?)
              else
                add_neo_relationship(self.neo_node, child[i].neo_node, method, child[i].top_level_node?)
              end
              child[i] = child[i].class.new(:idref => child[i].id)
              child[i].parent = self
            end
          elsif child[i].respond_to?(:flatten_relationships!)
            child[i].flatten_relationships!(method)
          end
        end
      elsif child.respond_to?(:flatten_relationships!)
        child.flatten_relationships!(method)
      end
    end
  end

  def should_deref?(child)
    SHOULD_DEREF.keys.find {|klass| child.kind_of?(klass)}
  end

  def mongo_collection
    @mongo_collection ||= self.class.mongo_collection
  end

  def verify_id!
    raise "Unable to persist non-IDable constructs" unless self.respond_to?(:id)
    self.generate_id! if self.id.nil?
  end

  def to_json_hash
    annotate_class!
    coll = self.class.stix_fields.inject({'@@class' => self.class.to_s}) do |coll, field|
      name = field.name.underscore
      name = "ttps" if name == "tt_ps"
      name = "coas" if name == "co_as"
      name = "alternative_ids" if name == "alternative_i_ds"
      resp = self.send(name)

      if resp.nil? || resp.respond_to?(:length) && resp.length == 0
        # Do nothing
      elsif resp.respond_to?(:to_json_hash)
        coll[name] = resp.to_json_hash
      elsif resp.kind_of?(Java::JavaUtil::ArrayList) && resp.length > 0
        if resp.first.respond_to?(:to_json_hash)
          coll[name] = resp.map(&:to_json_hash)
        else
          coll[name] = resp.to_a
        end
      elsif resp.kind_of?(Java::JavaxXmlNamespace::QName)
        coll[name] = {
          namespace: resp.namespace_uri,
          local_part: resp.local_part,
          prefix: resp.prefix
        }
      elsif resp.respond_to?(:value)
        coll[name] = resp.value
      elsif resp.class.to_s =~ /XMLGregorianCalendarImpl/
        coll[name] = resp.to_s
      else
        coll[name] = resp
      end
      coll
    end

    if self.respond_to?(:value) && !self.value.nil?
      if self.value.respond_to?(:to_json_hash)
        coll['value'] = self.value.to_json_hash
      elsif self.value.class.to_s =~ /XMLGregorianCalendarImpl/
        coll['value'] = value.to_s
      else
        coll['value'] = value
      end
    end

    return coll
  end

  def to_json
    to_json_hash.to_json
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

  module ClassMethods
    def find(id)
      mongo_obj = if id =~ /^\w+:[\w-]+$/
        mongo_collection.find({'id.local_part' => id.split(':').last, 'id.prefix' => id.split(':').first}).first
      elsif id =~ /^\{(.+)\}(.+)$/
        full,ns,local = id.match(/^\{(.+)\}(.+)$/).to_a
        mongo_collection.find({'id.local_part' => local, 'id.namespace' => ns}).first
      else
        mongo_collection.find({'id.local_part' => id.split(':').last, 'id.prefix' => ''}).first
      end

      if mongo_obj
        self.from_mongo(mongo_obj)
      else
        nil
      end
    end

    def from_mongo(mongo_obj)
      obj = self.new(mongo_obj.except('_id', '@@class'))
      obj.mongo_document = mongo_obj
      obj.neo_node = Neography::Node.find("node_id_index", "id", id, $neography) rescue nil
      return obj
    end

    def query(args = {})
      mongo_collection.find(args).to_a.map {|item| self.from_mongo(item)}
    end

    def search(term)
      self.mongo_collection.find({"title" => Regexp.new(term)}).to_a.map {|i| self.from_mongo(i)}
    end

    def all
      mongo_objects = mongo_collection.find.to_a

      mongo_objects.map do |mongo_object|
        obj = self.new(mongo_object.except('_id', '@@class'))
        obj.mongo_document = mongo_object
        obj.neo_node = Neography::Node.find("node_id_index", "id", mongo_object.id, $neography) rescue nil
        obj
      end
    end

    def count
      mongo_collection.count
    end

    def mongo_collection
      @mongo_collection ||= $mongo_db[self.collection_name]
    end

    def collection_name
      to_s
    end

    def find!(id)
      it = find(id)
      raise "Unable to find node by id for: #{id}" if it.nil?
      return it
    end

    def from_node(node)
      stix = self.new
      stix.node = node
      node.props.each do |name, val|
        if name == :stix_id
          stix.id = val
        else
          stix.send("#{name}=", val)
        end
      end

      return stix
    end

    def from_json(json)
      self.new(JSON.parse(json))
    end

    def namespace
      @namespace ||= self.java_class.package.annotations.first.namespace
    end

    def name
      @name ||= self.java_class.annotations.select {|a| a.annotation_type.to_s == "javax.xml.bind.annotation.XmlType"}.first.name
    end

    def stix_fields
      own_fields = self.java_class.declared_fields
      super_fields = self.superclass.respond_to?(:stix_fields) ? self.superclass.stix_fields : []
      own_fields + super_fields
    end
  end
end
