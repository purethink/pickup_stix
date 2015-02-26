class Identity

  include Mongoid::Document
  include OmniAuth::Identity::Models::Mongoid

  field :email
  field :password_digest
  field :name

  validates_uniqueness_of :email
end
