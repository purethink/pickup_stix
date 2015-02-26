class User

  include Mongoid::Document

  field :provider
  field :uid
  field :name

  after_create :create_node

  BOOKMARKABLE_CLASSES = TOP_LEVEL_TYPES.map(&:name) # I.e. all top-level STIX types

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      if auth['info']
         user.name = auth['info']['name'] || ""
      end
    end
  end

  def has_bookmark?(target)
    self.node.rels(dir: :outgoing, between: target.node, labels: [:bookmark]).first.present?
  end

  def add_bookmark(target)
    Neo4j::Relationship.create(:bookmark, self.node, target.node)
  end

  def remove_bookmark(target)
    self.node.rels(dir: :outgoing, between: target.node, labels: [:bookmark]).first.try(&:del)
  end

  def create_node
    @neo_node = Neo4j::Node.create({"id" => self.id.to_s, "title" => name, "class" => 'User'}, 'User')
  end

  def node
    @node ||= Neo4j::Label.find_nodes('User', :id, self.id.to_s).first
  end
end
