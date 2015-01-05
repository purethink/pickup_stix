require 'rails_helper'

describe STIXPackage do
  context "class" do
    it "should be able to parse a document" do
      stix = STIXPackage.from_xml(File.read('spec/test_data/fireeye-pivy-report.xml'))

      expect(stix.stix_header.title).to eq("Poison Ivy: Assessing Damage and Extracting Intelligence")
    end

    it "should be able to find a node" do
      STIXPackage.mongo_collection.insert({"id" => "1234", "version" => "1.1.1"})

      package = STIXPackage.find("1234")
      expect(package).not_to be_nil
      expect(package.version).to eq("1.1.1")
    end
  end

  context "instance" do
    it "should be able to persist a node" do
      stix = STIXPackage.new
      stix.persist!

      expect(STIXPackage.mongo_collection.count).to eq(1)
    end

    it "should assign an ID if the construct doesn't have one" do
      stix = STIXPackage.new
      stix.id = nil
      expect(stix.id).to be_nil

      stix.verify_id!
      expect(stix.id).not_to be_nil
    end
  end
end
