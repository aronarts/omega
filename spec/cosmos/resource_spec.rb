# resource module tests
#
# Copyright (C) 2012-2013-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'cosmos/resource'
require 'rjr/common'

module Cosmos
describe Resource do
  describe "#type" do
    it "returns type" do
      @r = Resource.new :material_id => 'metal-steel'
      @r.type.should == 'metal'
    end
  end

  describe "#name" do
    it "returns name" do
      @r = Resource.new :material_id => 'metal-steel'
      @r.name.should == 'steel'
    end
  end

  describe "#initialize" do
    it "sets defaults" do
      @r = Resource.new
      @r.id.should be_nil
      @r.entity_id.should be_nil
      @r.entity.should be_nil
      @r.quantity.should == 0
    end

    it "sets attributes" do
      a = build(:asteroid)
      @r = Resource.new :id => 'metal-steel',
                        :entity => a,
                        :quantity => 500
      @r.id.should == 'metal-steel'
      @r.entity_id.should == a.id
      @r.entity.should == a
      @r.quantity.should == 500
    end
  end

  describe "#valid?" do
    before(:each) do
      @a  = build(:asteroid)
      @r = Resource.new :id => 'resource42',
                        :material_id => 'metal-steel',
                        :entity => @a,
                        :quantity => 50
    end

    context "id is invalid" do
      it "returns false" do
        @r.id = nil
        @r.should_not be_valid
      end
    end

    context "material_id is invalid" do
      it "returns false" do
        @r.material_id = 'foobar'
        @r.should_not be_valid
      end
    end

    context "entity_id is invalid" do
      it "returns false" do
        @r.entity_id = nil
        @r.should_not be_valid
      end
    end

    context "entity is invalid" do
      it "returns false" do
        @a.location = nil
        @r.should_not be_valid
      end
    end

    context "quantity is invalid" do
      it "returns false" do
        @r.quantity = "0"
        @r.should_not be_valid
      end
    end

    it "returns true" do
      @r.should be_valid
    end
  end

  describe "#to_json" do
    it "returns resource in json format" do
      a = build(:asteroid)
      r = Resource.new :id => 'metal-titanium', :entity => a, :quantity => 50

      j = r.to_json
      j.should include('"json_class":"Cosmos::Resource"')
      j.should include('"id":"metal-titanium"')
      j.should include('"entity_id":"'+a.id+'"')
      j.should include('"quantity":50')
    end
  end

  describe "#json_create" do
    it "returns resource from json format" do
      j = '{"json_class":"Cosmos::Resource","data":{"id":"metal-titanium","quantity":50,"entity_id":"ast1"}}'
      r = ::RJR::JSONParser.parse(j)

      r.class.should == Cosmos::Resource
      r.id.should == 'metal-titanium'
      r.entity_id.should == 'ast1'
      r.quantity.should == 50
    end
  end

end # describe Resource
end # module Cosmos

  # TODO:
  #it "should successfully accept resource to copy" do
  #   resource1   = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
  #   resource2   = Cosmos::Resource.new :resource => resource1
  #   resource2.name.should == 'titanium'
  #   resource2.type.should == 'metal'
  #   resource2.id.should == "metal-titanium"
  #end

  #it "should automatically generate a uuid id if not specified" do
  #  rs = Cosmos::ResourceSource.new
  #  rs.id.should_not be_nil
  #  rs.id.should =~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/
  #end
