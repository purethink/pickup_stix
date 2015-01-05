require 'ruby_stix/api'

require 'app/models/qname'
require 'app/models/campaign_type'
require 'app/models/course_of_action_type'
require 'app/models/exploit_target_type'
require 'app/models/incident_type'
require 'app/models/observable_type'
require 'app/models/stix_type'
require 'app/models/threat_actor_type'
require 'app/models/ttp_type'
require 'app/models/indicator_type'
require 'app/models/courses_of_action_type'
require 'app/models/related_object_type'

Dir.glob('app/models/org/**/*.rb').each {|f| require(f)}

include StixRuby::Aliases

COMPONENT_TYPES = {
  'Campaigns'         => Campaign,
  'Courses of Action' => CourseOfAction,
  'Exploit Targets'   => ExploitTarget,
  'Incidents'         => Incident,
  'Indicators'        => Indicator,
  'Observables'       => Observable,
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

# Add some indices

COMPONENT_TYPES.values.each {|klass| klass.mongo_collection.ensure_index({title: 'text'})}
STIXPackage.mongo_collection.ensure_index({'stix_header.title' => 'text'})
