# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

Rails.env ||= 'development'

namespace :db do
  task :reset do
    mongo_client = Mongo::MongoClient.new
    
    neo_session = Neo4j::Session.open(:server_db)
    
    stix = Neo4j::Label.create(:stix)
    stix.create_index :stix_id
    
    Neo4j::Session.query("MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r")
    mongo_client.drop_database("stix-#{Rails.env}")
  end
end