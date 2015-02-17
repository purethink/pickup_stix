class QueriesController < ApplicationController

  # Returns the list of TTPs relevant to the given indicators
  def ttps_for_indicators
    ids = params[:indicator_ids].map {|id| "n.stix_id=\"#{id}\""}.join(" OR ")

    query = "START n=node(*) WHERE (#{ids}) MATCH (n)-->(ttps {class:\"Java::OrgMitreStixCommon::TTPBaseType\"}) RETURN ttps.stix_id"

    n = Neo4j::Session.query(query).to_a.map {|i| i['ttps.stix_id']}

    ttps = TTP.find(n)

    package = STIXPackage.new

    ttps.each do |ttp|
      package.add_ttp(ttp)
    end

    render :xml => package.to_xml
  end

  # Returns the list of COAs relevant to the given TTPs
  def coas_for_ttps
    ids = params[:ttp_ids].map {|id| "n.stix_id=\"#{id}\""}.join(" OR ")

    query = "START n=node(*) WHERE (#{ids}) MATCH (n)<--(indicators {class:\"Java::OrgMitreStixCommon::IndicatorBaseType\"})-->(coas {class:\"Java::OrgMitreStixCommon::CourseOfActionBaseType\"}) RETURN DISTINCT coas.stix_id"
    n = Neo4j::Session.query(query).to_a.map {|i| i['coas.stix_id']}

    coas = CourseOfAction.find(n)

    package = STIXPackage.new

    coas.each do |coa|
      package.add_course_of_action(coa)
    end

    render :xml => package.to_xml
  end

  def logs
    src_ip = params[:source_ip]
    dst_ip = params[:destination_ip]

    obj = $mongo_db['Java::OrgMitreCyboxCore::ObjectType'].find(:$or => [{'properties.address_value.value' => src_ip}, 'properties.address_value.value' => dst_ip]).first

    if obj
      id = "stix_id=\"#{obj['id']['namespace']}:::#{obj['id']['local_part']}\""
      query = "START n=node(*) WHERE (#{id}) MATCH (n)<-[1]-(indicators {class:\"Java::OrgMitreStixCommon::IndicatorBaseType\"}) RETURN indicators"
      raise query
      n = Neo4j::Session.query(query).to_a.map {|i| i['indicators.stix_id']}

      indicators = Indicator.find(n)

      render :json => {:match => true}
    else
      render :json => {:match => false}
    end
  end

  private

end
