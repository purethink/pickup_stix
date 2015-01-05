$mongo_client = Mongo::MongoClient.new
$mongo_db = $mongo_client["cycs-#{Rails.env}"]

$neography = Neography::Rest.new(
  :directory => "cycs-#{Rails.env}"
)

org.mitre.ApiHelper.send(:include, Serializer)
