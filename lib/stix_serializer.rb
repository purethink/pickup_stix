module StixSerializer

  def self.included(klass)
    klass.send(:extend, StixSerializer::ClassMethods)
    klass.send(:attr_accessor, :document)
    klass.send(:attr_accessor, :node)
  end

  def delete
    raise "Unimplemented"
  end

  def _id
    document['_id'].to_s
  end

  def save(default_args = {})
    # Create the vertex if it doesn't exist already
    self.generate_id! if self.id.nil?
    document = {}

    @node = find_or_create_node
    process_information_source(default_args) if (self.respond_to?(:information_source) || self.respond_to?(:producer)) && !self.kind_of?(Java::OrgMitreCyboxCore::ObservableType)
    process_handling(default_args) if self.respond_to?(:handling) && !self.kind_of?(Java::OrgMitreCyboxCore::ObservableType)
    build_hash(self, default_args).each {|k, v| document[k] = v}

    if existing_document = mongo_collection.find(self.class.query_from_id(self.id_string)).first
      @document = existing_document
      @document.update({:stix => document})
    else
      @document = mongo_collection.insert({:stix => document})
    end

    return true
  end

  def process_handling(args)
    if args[:markings]
      self.handling ||= Java::OrgMitreData_marking::MarkingType.new
      self.handling.markings ||= []
      args[:markings].each do |marking|
        specification = Java::OrgMitreData_marking::MarkingSpecificationType.new(:controlled_structure => "../../../descendant-or-self::node() | ../../../descendant-or-self::node()/@*", :marking_structures => [marking])
        self.handling.markings << specification
      end
    end

    args[:markings] ||= []
    if self.handling.present?
      self.handling.markings.each do |marking|
        if marking.controlled_structure == "//node()" || marking.controlled_structure == "//node() | //@*"
          marking.marking_structures.each do |st|
            args[:markings] << st
          end
        end
      end
    end
  end


  def process_information_source(args)
    method = self.respond_to?(:information_source) ? :information_source : :producer

    if self.send(method).present?
      args[:information_source] = self.send(method)
    else
      self.send("#{method}=", args[:information_source])
    end
  end

  def find_or_create_node
    self.class.find_or_create_node(self.id_string, self.respond_to?(:title) ? self.title : nil)
  end

  def destroy
    raise "Unimplemented"
  end

  def dereference
    klass = Java::OrgMitre::ApiHelper::SHOULD_FLATTEN[self.class] || self.class
    klass.find(self.id_string)
  end

  def relationships(direction = nil)
    if direction.present?
      relationships = node.rels(:dir => direction).to_a
    else
      relationships = node.rels.to_a
    end
    relationships.inject({}) do |coll, obj|
      coll[obj['type']] ||= []
      if obj.end_node.neo_id == node.neo_id
        coll[obj['type']] << obj.start_node
      else
        coll[obj['type']] << obj.end_node
      end
      coll
    end
  end

  def add_relationship(to, descriptor)
    to_node = to.kind_of?(Neo4j::Node) ? to : to.node
    if self.node.rels(:dir => :outgoing, :between => to_node).to_a.length < 1
      relationship = Neo4j::Relationship.create(descriptor, self.node, to_node, {'type' => descriptor})
    end
  end

  def mongo_collection
    self.class.mongo_collection
  end

  module ClassMethods
    def find_node(id_string, title = nil)
      begin
        node = Neo4j::Label.find_nodes(collection_name, :stix_id, id_string).first
        node['title'] = title if title.present?

        return node
      rescue
        nil
      end
    end

    def find(id)
      ids = Array.wrap(id)
      docs = mongo_collection.find(:$or => ids.map {|i| query_from_id(i)}).to_a

      if id.kind_of?(Array)
        return docs.map {|doc| from_mongo(doc)}
      elsif docs.length == 0
        return nil
      else
        return from_mongo(docs.first)
      end
    end

    def find_by_mongo_id(id)
      id = BSON::ObjectId.from_string(id) if id.kind_of?(String)
      doc = mongo_collection.find(:_id => id).first

      if doc
        from_mongo(doc)
      else
        nil
      end
    end

    def query_from_id(id)
      if id =~ /^\w+:[\w-]+$/
        {'stix.id.local_part' => id.split(':').last, 'stix.id.prefix' => id.split(':').first}
      elsif id =~ /^\{(.+)\}(.+)$/
        full,ns,local = id.match(/^\{(.+)\}(.+)$/).to_a
        {'stix.id.local_part' => local, 'stix.id.namespace' => ns}
      else
        {'stix.id.local_part' => id.split(':').last, 'stix.id.prefix' => ''}
      end
    end

    def create_node(id_string, title = nil)
      Neo4j::Node.create({"stix_id" => id_string, "title" => title, "class" => collection_name}, collection_name)
    end

    def create(args = {})
      obj = self.new(args)
      obj.save
      return obj
    end

    def first
      doc = mongo_collection.find.first
      doc.present? ? from_mongo(doc) : nil
    end

    def from_mongo(mongo_obj)
      obj = self.new(mongo_obj['stix'])
      obj.document = mongo_obj
      obj.node = self.find_node(obj.id_string)
      return obj
    end

    def query(args = {})
      mongo_collection.find(args).to_a.map {|item| self.from_mongo(item)}
    end

    def search(term)
      self.mongo_collection.find({"stix.title" => Regexp.new(term)}).to_a.map {|i| self.from_mongo(i)}
    end

    def all
      mongo_collection.find.to_a.map {|mo| from_mongo(mo)}
    end

    def count
      mongo_collection.count
    end

    def mongo_collection
      @mongo_collection ||= $mongo_db[self.collection_name]
    end

    def collection_name
      if superclass.respond_to?(:collection_name)
        superclass.collection_name
      else
        to_s
      end
    end

    def find_or_create_node(id_string, title = nil)
      find_node(id_string, title) || create_node(id_string, title)
    end

    def human_name
      self.name.underscore.split('/').last.gsub('_type', '').gsub('_base', '')
    end
  end
end
