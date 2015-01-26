module Serializer
  
  def self.included(klass)
    klass.send(:extend, Serializer::ClassMethods)
    klass.send(:attr_accessor, :document)
    klass.send(:attr_accessor, :node)
  end
  
  def delete
    raise "Unimplemented"
  end
  
  def save
    # Create the vertex if it doesn't exist already
    self.generate_id! if self.id.nil?
    document = {}

    @node = find_or_create_node
    build_hash(self).each {|k, v| document[k] = v}
    @document = mongo_collection.insert(document)
  
    return true
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
      relationships = $neography.get_node_relationships(node, direction)
    else
      relationships = $neography.get_node_relationships(node)
    end
    relationships.inject({}) do |coll, obj|
      coll[obj['type']] ||= []
      if obj['end'].split('/').last == node.neo_id
        coll[obj['type']] << Neography::Node.load(obj['start'])
      else
        coll[obj['type']] << Neography::Node.load(obj['end'])
      end
      coll
    end
  end

  def add_relationship(to, descriptor)
    to_node = to.respond_to?(:node) ? to.node : to
    $neography.create_relationship(descriptor, self.node, to_node)
  end
  
  def mongo_collection
    self.class.mongo_collection
  end
  
  module ClassMethods
    def find_node(id_string)
      begin
        Neography::Node.find('stix', 'stix_id', id_string)
      rescue
        nil
      end
    end
    
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

    def create_node(id_string, title = nil)
      node = Neography::Node.create({"stix_id" => id_string, "title" => title, "@@class" => collection_name}, $neography)
      node.add_to_index('stix', 'stix_id', id_string)
      return node
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
      obj = self.new(mongo_obj.except('_id', '@@class'))
      obj.document = mongo_obj
      obj.node = self.find_node(obj.id_string)
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
        obj.document = mongo_object
        obj.node = Neography::Node.find("node_id_index", "id", mongo_object.id, $neography) rescue nil
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
      if superclass.respond_to?(:collection_name)
        superclass.collection_name
      else
        to_s
      end
    end
    
    def find_or_create_node(id_string, title = nil)
      find_node(id_string) || create_node(id_string, title)
    end
  end
end