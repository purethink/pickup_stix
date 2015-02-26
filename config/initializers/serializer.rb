$mongo_db = Mongoid.default_session
$neo_session = Neo4j::Session.open(:server_db)
