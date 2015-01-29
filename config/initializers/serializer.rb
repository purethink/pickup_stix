$mongo_client = Mongo::MongoClient.new
$mongo_db = $mongo_client["stix-#{Rails.env}"]

$neo_session = Neo4j::Session.open(:server_db)