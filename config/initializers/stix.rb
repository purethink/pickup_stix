require 'ruby_stix/api'
include StixRuby::Aliases

require 'lib/api_helper'
require 'lib/stix_serializer'

Dir.glob('app/models/org/**/*.rb').each {|f| require(f)}
Dir.glob('app/models/javax/**/*.rb').each {|f| require(f)}

COMPONENT_TYPES = {
  'Campaigns'         => Campaign,
  'Courses of Action' => CourseOfAction,
  'Exploit Targets'   => ExploitTarget,
  'Incidents'         => Incident,
  'Indicators'        => Indicator,
  'Observables'       => org.mitre.cybox.core.ObservableType,
  'TTPs'              => TTP,
  'Threat Actors'     => ThreatActor
}

DEFAULT_IMPLEMENTATIONS = {
  org.mitre.stix.common.CampaignBaseType         => Campaign,
  org.mitre.stix.common.CourseOfActionBaseType   => CourseOfAction,
  org.mitre.stix.common.ExploitTargetBaseType    => ExploitTarget,
  org.mitre.stix.common.IncidentBaseType         => Incident,
  org.mitre.stix.common.IndicatorBaseType        => Indicator,
  org.mitre.stix.common.TTPBaseType              => TTP,
  org.mitre.stix.common.ThreatActorBaseType      => ThreatActor
}

TOP_LEVEL_TYPES = (DEFAULT_IMPLEMENTATIONS.values + DEFAULT_IMPLEMENTATIONS.keys + [STIXPackage, Observable]).to_set

Java::OrgMitre::ApiHelper::SHOULD_FLATTEN.keys.each do |key|
  key.send(:include, StixSerializer)
end

# Add some indices
COMPONENT_TYPES.values.each {|klass| klass.mongo_collection.indexes.create({title: 'text'})}
STIXPackage.mongo_collection.indexes.create({'stix_header.title' => 'text'})
