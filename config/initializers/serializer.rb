$mongo_client = Mongo::MongoClient.new
$mongo_db = $mongo_client["stix-#{Rails.env}"]

$neography = Neography::Rest.new(
  :directory => "stix-#{Rails.env}"
)
