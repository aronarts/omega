# cosmos::create_resource,cosmos::get_resources tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/rjr/get'
require 'rjr/dispatcher'

module Cosmos::RJR
  describe "#create_resource" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :RESOURCES_METHODS
      @registry = Cosmos::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
    end

    context "resource is not a valid resource" do
      it "raises ArgumentError" do
        lambda {
          @s.create_resource 42
        }.should raise_error(ArgumentError)

        a = build(:asteroid)
        r = build(:resource, :id => nil, :entity => a, :quantity => 10)
        lambda {
          @s.create_resource r
        }.should raise_error(ArgumentError)
      end
    end

    context "quantity is <0" do
      it "raises ArgumentError" do
        a = build(:asteroid)
        r = build(:resource, :entity => a, :quantity => -1)
        lambda {
          @s.create_resource r
        }.should raise_error(ArgumentError)
      end
    end

    context "entity not found" do
      it "raises DataNotFound" do
        r = build(:resource, :entity_id => 'foobar', :quantity => 1)
        lambda {
          @s.create_resource r
        }.should raise_error(ArgumentError)
      end
    end

    context "entity cannot accept resource" do
      it "raises ArgumentError" do
        g = build(:galaxy)
        r = build(:resource, :entity => g, :quantity => 1)
        lambda {
          @s.create_resource r
        }.should raise_error(ArgumentError)
      end
    end

    context "insufficient privileges (modify-cosmos_entities)" do
      it "raises PermissionError" do
        a = build(:asteroid)
        r = build(:resource, :entity => a, :quantity => 1)
        lambda {
          @s.create_resource r
        }.should raise_error(PermissionError)
      end
    end

    it "adds resource to entity" do
      add_privilege(@login_role, 'modify', 'cosmos_entities')
      a = build(:asteroid)
      r = build(:resource, :entity => a, :quantity => 1)
      @s.create_resource r
      Cosmos::RJR.registry.entity(&with_id(a.id)).resources.size.should == 1
      Cosmos::RJR.registry.entity(&with_id(a.id)).resources.first.id.should == r.id
    end
 
    it "returns nil" do
      add_privilege(@login_role, 'modify', 'cosmos_entities')
      a = build(:asteroid)
      r = build(:resource, :entity => a, :quantity => 1)
      @s.create_resource(r).should be_nil
    end
  end # describe #create_resource

  describe "#get_resources" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :RESOURCES_METHODS
      @registry = Cosmos::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
    end

    context "entity not found" do
      it "raises DataNotFound" do
        @s.get_resources 'nonexistant'
      end
    end

    context "insufficient privileges (view-cosmos_entities)" do
      it "raises PermissionError" do
        a = create(:asteroid)
        lambda{
          @s.get_resources a.id
        }.should raise_error(PermissionError)
      end
    end

    it "returns entity resources" do
      add_privilege(@login_role, 'modify', 'cosmos_entities')
      a = build(:asteroid)
      r = build(:resource, :entity => a, :quantity => 1)
      @s.create_resource(r).should be_nil

      add_privilege(@login_role, 'view', 'cosmos_entities')
      rs = @s.get_resources(a.id)
      rs.size.should == 1
      rs.first.id.should == r.id
    end
  end # describe #get_resources

  describe "#dispatch_cosmos_rjr_resources" do
    it "adds cosmos::create_resource to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_resources(d)
      d.handlers.keys.should include("cosmos::create_resource")
    end

    it "adds cosmos::get_resources to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_resources(d)
      d.handlers.keys.should include("cosmos::get_resources")
    end
  end

end #module Cosmos::RJR