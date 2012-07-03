# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'
require 'rjr/local_node'

describe Manufactured::RJRAdapter do

  before(:all) do
    Motel::RJRAdapter.init
    Users::RJRAdapter.init
    Cosmos::RJRAdapter.init
    Manufactured::RJRAdapter.init
    @local_node = RJR::LocalNode.new :node_id => 'omega-test'
  end

  before(:each) do
    Motel::Runner.instance.clear
    Cosmos::Registry.instance.init
    Manufactured::Registry.instance.init

    # create a few test users
    #  (can't Users::Registry.init since subsystems may have registed users)
    @testuser1 = Users::User.new :id => 'user42'
    @testuser2 = Users::User.new :id => 'user43'
    Users::Registry.instance.create @testuser1
    Users::Registry.instance.create @testuser2
  end

  after(:each) do
    Users::Registry.instance.remove @testuser1.id
    Users::Registry.instance.remove @testuser2.id

    Manufactured::Registry.instance.terminate
  end

  after(:all) do
    Motel::Runner.instance.stop
  end

  it "should permit users with create manufactured_entities to create_entity" do
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '101')
    stat2 = Manufactured::Station.new :id => 'station2', :user_id => 'user1', :location => Motel::Location.new(:id => '102')
    fleet1 = Manufactured::Fleet.new :id => 'fleet1', :user_id => 'user1'
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    u = TestUser.create.login(@local_node).clear_privileges

    gal1.add_child(sys1)
    ship1.parent = stat1.parent = stat2.parent = sys1

    Motel::Runner.instance.clear
    Motel::Runner.instance.locations.size.should == 0

    Manufactured::Registry.instance.init
    Manufactured::Registry.instance.ships.size.should == 0
    Manufactured::Registry.instance.stations.size.should == 0
    Manufactured::Registry.instance.fleets.size.should == 0

    # invalid type
    lambda {
      @local_node.invoke_request('manufactured::create_entity', 1)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)


    # valid data, no permissions
    lambda{
      @local_node.invoke_request('manufactured::create_entity', ship1)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    Motel::Runner.instance.locations.size.should == 0

    u.add_privilege('create', 'manufactured_entities')

    # parent system not found
    lambda{
      @local_node.invoke_request('manufactured::create_entity', ship1)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    Motel::Runner.instance.locations.size.should == 0

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Cosmos::Registry.instance.add_child gal1

    lambda{
      rship1 = @local_node.invoke_request('manufactured::create_entity', ship1)
      rstat1 = @local_node.invoke_request('manufactured::create_entity', stat1)
      rstat2 = @local_node.invoke_request('manufactured::create_entity', stat2)
      rfleet = @local_node.invoke_request('manufactured::create_entity', fleet1)

      rship1.class.should == Manufactured::Ship
      rship1.id.should == ship1.id
      rstat1.class.should == Manufactured::Station
      rstat1.id.should == stat1.id
      rstat2.class.should == Manufactured::Station
      rstat2.id.should == stat2.id
      rfleet.class.should == Manufactured::Fleet
      rfleet == rfleet.id
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should    == 1
    Manufactured::Registry.instance.stations.size.should == 2
    Manufactured::Registry.instance.fleets.size.should   == 1

    Motel::Runner.instance.locations.size.should == 5 # locations created for system, galaxy, ships, stations

    (Manufactured::Registry.instance.ships + Manufactured::Registry.instance.stations).each { |e|
      Motel::Runner.instance.locations.collect { |l| l.id }.include?(e.location.id).should be_true
      e.location.parent_id.should == sys1.location.id
      e.location.parent.id.should == sys1.location.id
    }
  end

  it "should verify entity ids are unique when creating entities" do
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '101')
    stat2 = Manufactured::Station.new :id => 'station2', :user_id => 'user1', :location => Motel::Location.new(:id => '102')
    fleet1 = Manufactured::Fleet.new :id => 'fleet1', :user_id => 'user1'
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    u = TestUser.create.login(@local_node).clear_privileges.add_privilege('create', 'manufactured_entities')

    gal1.add_child(sys1)
    ship1.parent = stat1.parent = stat2.parent = sys1

    Manufactured::Registry.instance.init
    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Cosmos::Registry.instance.add_child gal1

    # valid request
    lambda{
      @local_node.invoke_request('manufactured::create_entity', ship1)
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should    == 1

    # id already taken
    lambda{
      @local_node.invoke_request('manufactured::create_entity', ship1)
    #}.should raise_error(ArgumentError)
    }.should raise_error

    Manufactured::Registry.instance.ships.size.should    == 1
  end

  it "should permit users with create manufactured_entities to construct_entity" do
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1',
                                      :location => Motel::Location.new(:id => '101', :x => 50, :y => 60, :z => -70),
                                      :resources => { 'metal-alloy' => 5000 }
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    u = TestUser.create.login(@local_node).clear_privileges

    gal1.add_child(sys1)
    stat1.parent = sys1

    Motel::Runner.instance.clear
    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.locations.size.should == 2
    Cosmos::Registry.instance.add_child gal1

    Manufactured::Registry.instance.init
    Manufactured::Registry.instance.create stat1
    Manufactured::Registry.instance.ships.size.should == 0
    Manufactured::Registry.instance.stations.size.should == 1

    lambda{
      @local_node.invoke_request('manufactured::construct_entity', 'non_existant', 'Manufactured::Ship')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::construct_entity', stat1, 'Manufactured::Ship')
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('create', 'manufactured_entities')

    lambda{
      rship = @local_node.invoke_request('manufactured::construct_entity', stat1.id, 'Manufactured::Ship', 'type', 'battlecruiser')
      rship.class.should == Manufactured::Ship
      rship.parent.name.should == sys1.name
      rship.location.should_not be_nil
      rship.type.should == :battlecruiser
      rship.size.should == Manufactured::Ship::SHIP_SIZES[:battlecruiser]
      rship.user_id = u.id
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should == 1
    Motel::Runner.instance.locations.size.should == 3
  end

  it "should accept params to instantiate manufactured_entities with when invoking construct_entity" do
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1',
                                      :location => Motel::Location.new(:id => '101', :x => 0, :y => 0, :z => 0),
                                      :resources => { 'metal-alloy' => 5000 }
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    u = TestUser.create.login(@local_node).clear_privileges

    gal1.add_child(sys1)
    stat1.parent = sys1

    Motel::Runner.instance.clear
    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Cosmos::Registry.instance.add_child gal1

    Manufactured::Registry.instance.init
    Manufactured::Registry.instance.create stat1

    u.add_privilege('create', 'manufactured_entities')

    lambda{
      rship = @local_node.invoke_request('manufactured::construct_entity', stat1.id, 'Manufactured::Ship')
      rship.should_not be_nil
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should == 1

    # verify defaults
    Manufactured::Registry.instance.ships[0].type.should == :frigate
    Manufactured::Registry.instance.ships[0].size.should == Manufactured::Ship::SHIP_SIZES[:frigate]
    Manufactured::Registry.instance.ships[0].location.x.should == stat1.location.x + 10
    Manufactured::Registry.instance.ships[0].location.y.should == stat1.location.y + 10
    Manufactured::Registry.instance.ships[0].location.z.should == stat1.location.z + 10

    lambda{
      rship = @local_node.invoke_request('manufactured::construct_entity', stat1.id, 'Manufactured::Ship', 'type', 'transport', 'size', Manufactured::Ship::SHIP_SIZES[:transport])
      rship.should_not be_nil
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should == 2

    # verify set params
    Manufactured::Registry.instance.ships[1].type.should == :transport
    Manufactured::Registry.instance.ships[1].size.should == Manufactured::Ship::SHIP_SIZES[:transport]
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to get_entity" do
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    u = TestUser.create.login(@local_node).clear_privileges

    gal1.add_child(sys1)
    ship1.parent = sys1

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run ship1.location
    Cosmos::Registry.instance.add_child gal1
    Manufactured::Registry.instance.create ship1

    lambda{
      @local_node.invoke_request('manufactured::get_entity', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::get_entity', ship1.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('view', 'manufactured_entities')

    lambda{
      rship = @local_node.invoke_request('manufactured::get_entity', ship1.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == ship1.id
    }.should_not raise_error

    u.clear_privileges.add_privilege('view', 'manufactured_entity-' + ship1.id.to_s)

    lambda{
      rship = @local_node.invoke_request('manufactured::get_entity', ship1.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == ship1.id
    }.should_not raise_error
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to get_entities_from_location" do
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '101')
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    u = TestUser.create.login(@local_node).clear_privileges

    gal1.add_child(sys1)
    ship1.parent = sys1
    stat1.parent = sys1

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run ship1.location
    Motel::Runner.instance.run stat1.location
    Cosmos::Registry.instance.add_child gal1
    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create stat1

    lambda{
      @local_node.invoke_request('manufactured::get_entity_from_location', 'Manufactured::Ship', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::get_entity_from_location', 'Manufactured::Ship', stat1.location.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::get_entity_from_location', 'Manufactured::Ship', ship1.location.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('view', 'manufactured_entities')

    lambda{
      entity = @local_node.invoke_request('manufactured::get_entity_from_location', 'Manufactured::Ship', ship1.location.id)
      entity.class.should == Manufactured::Ship
      entity.id.should == ship1.id
    }.should_not raise_error

    lambda{
      entity = @local_node.invoke_request('manufactured::get_entity_from_location', 'Manufactured::Station', stat1.location.id)
      entity.class.should == Manufactured::Station
      entity.id.should == stat1.id
    }.should_not raise_error
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to get_entities_under" do
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100')
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200')
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201')
    u = TestUser.create.login(@local_node).clear_privileges

    gal1.add_child(sys1)
    ship1.parent = sys1

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run ship1.location
    Cosmos::Registry.instance.add_child gal1
    Manufactured::Registry.instance.create ship1

    lambda{
      @local_node.invoke_request('manufactured::get_entities_under', 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      entities = @local_node.invoke_request('manufactured::get_entities_under', sys1.id)
      entities.class.should == Array
      entities.size.should == 0
    }.should_not raise_error

    u.add_privilege('view', 'manufactured_entities')

    lambda{
      entities = @local_node.invoke_request('manufactured::get_entities_under', sys1.id)
      entities.class.should == Array
      entities.size.should == 1
      entities.first.class.should == Manufactured::Ship
      entities.first.id.should == ship1.id
      # TODO verify entities.first.location is latest tracked by motel
    }.should_not raise_error

    u.clear_privileges.add_privilege('view', 'manufactured_entity-' + ship1.id.to_s)

    lambda{
      entities = @local_node.invoke_request('manufactured::get_entities_under', sys1.id)
      entities.class.should == Array
      entities.size.should == 1
      entities.first.class.should == Manufactured::Ship
      entities.first.id.should == ship1.id
      # TODO verify entities.first.location is latest tracked by motel
    }.should_not raise_error
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to get_entities_for_user" do
    sys = Cosmos::SolarSystem.new
    ship1  = Manufactured::Ship.new :id => 'ship1', :user_id => @testuser1.id, :solar_system => sys, :location => Motel::Location.new(:id => '100')
    ship2  = Manufactured::Ship.new :id => 'ship2', :user_id => @testuser2.id, :solar_system => sys, :location => Motel::Location.new(:id => '100')
    u = TestUser.create.login(@local_node).clear_privileges

    Motel::Runner.instance.run ship1.location
    Motel::Runner.instance.run ship2.location
    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create ship2

    lambda{
      @local_node.invoke_request('manufactured::get_entities_for_user', 'non_existant', 'Manufactured::Ship')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      entities = @local_node.invoke_request('manufactured::get_entities_for_user', 'user42', 'Manufactured::Ship')
      entities.class.should == Array
      entities.size.should == 0
    }.should_not raise_error

    u.add_privilege('view', 'manufactured_entities')

    lambda{
      entities = @local_node.invoke_request('manufactured::get_entities_for_user', 'user42', 'Manufactured::Ship')
      entities.class.should == Array
      entities.size.should == 1
      entities.first.class.should == Manufactured::Ship
      entities.first.id.should == ship1.id
      # TODO verify entities.first.location is latest tracked by motel
    }.should_not raise_error

    u.clear_privileges.add_privilege('view', 'manufactured_entity-' + ship1.id.to_s)

    lambda{
      entities = @local_node.invoke_request('manufactured::get_entities_for_user', 'user42', 'Manufactured::Ship')
      entities.class.should == Array
      entities.size.should == 1
      entities.first.class.should == Manufactured::Ship
      entities.first.id.should == ship1.id
      # TODO verify entities.first.location is latest tracked by motel
    }.should_not raise_error
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to subscribe to events" do
    sys1 = Cosmos::SolarSystem.new
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys1,
                                   :location => Motel::Location.new(:id => '100', :x => 10, :y => 10, :z => 10)
    ship2 = Manufactured::Ship.new :id => 'ship2', :user_id => 'user1', :solar_system => sys1,
                                   :location => Motel::Location.new(:id => '101', :x => 10, :y => 10, :z => 5)
    u = TestUser.create.login(@local_node).clear_privileges.add_privilege('view', 'manufactured_entities')

    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create ship2
    rship2 = Manufactured::Registry.instance.ships.find { |s| s.id == 'ship2' }

    received_events, received_attackers, received_defenders = [],[],[]
    RJR::Dispatcher.add_handler('manufactured::event_occurred') { |*args|
      received_events << args[0]
      received_attackers << args[1]
      received_defenders << args[2]
    }

    lambda{
      @local_node.invoke_request('manufactured::subscribe_to', 'nonexistant', 'defended')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    rship2.notification_callbacks.size.should == 0

    lambda{
      rs = @local_node.invoke_request('manufactured::subscribe_to', ship2.id, 'defended')
      rs.class.should == Manufactured::Ship
      rs.id.should == rship2.id
    }.should_not raise_error

    rship2.notification_callbacks.size.should == 1
    rship2.notification_callbacks.first.endpoint_id.should == @local_node.message_headers['source_node']

    lambda{
      rs = @local_node.invoke_request('manufactured::subscribe_to', ship2.id, 'attacked')
      rs.class.should == Manufactured::Ship
      rs.id.should == rship2.id
    }.should_not raise_error

    rship2.notification_callbacks.size.should == 2

    # ensure duplicate events are overwritten
    lambda{
      rs = @local_node.invoke_request('manufactured::subscribe_to', ship2.id, 'attacked')
      rs.class.should == Manufactured::Ship
      rs.id.should == rship2.id
    }.should_not raise_error

    rship2.notification_callbacks.size.should == 2

    u.add_privilege('modify', 'manufactured_entity-' + ship1.id)
    @local_node.invoke_request('manufactured::attack_entity', ship1.id, ship2.id)
    sleep 1
    received_events.size.should > 0
    received_events.first.should == 'defended'

    # verify when user no longer has access to entity, callbacks are discontinued
    u.clear_privileges
    sleep 2
    rship2.notification_callbacks.size.should == 1 # TODO since only the 'defended' callback was triggered, just that was removed, need to remove all callbacks on loosing privs & other err cases
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to remove callbacks" do
    sys = Cosmos::SolarSystem.new
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys,
                                   :location => Motel::Location.new(:id => '100', :x => 10, :y => 10, :z => 10)
    ship2 = Manufactured::Ship.new :id => 'ship2', :user_id => 'user1', :solar_system => sys,
                                   :location => Motel::Location.new(:id => '101', :x => 10, :y => 10, :z => 5)
    u = TestUser.create.login(@local_node).clear_privileges.
                 add_privilege('view', 'manufactured_entities').
                 add_privilege('modify', 'manufactured_entities')

    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create ship2
    rship2 = Manufactured::Registry.instance.ships.find { |s| s.id == 'ship2' }

    received_events, received_attackers, received_defenders = [],[],[]
    RJR::Dispatcher.add_handler('manufactured::event_occurred') { |*args|
      received_events << args[0]
      received_attackers << args[1]
      received_defenders << args[2]
    }

    lambda{
      rloc = @local_node.invoke_request('manufactured::subscribe_to', ship2.id, 'defended')
      rloc.class.should == Manufactured::Ship
      rloc.id.should == ship2.id
    }.should_not raise_error

    rship2.notification_callbacks.size.should == 1

    u.clear_privileges

    lambda{
      rs = @local_node.invoke_request('manufactured::remove_callbacks', ship2.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('view', 'manufactured_entities').
      add_privilege('modify', 'manufactured_entities')

    lambda{
      rs = @local_node.invoke_request('manufactured::remove_callbacks', ship2.id)
      rs.class.should == Manufactured::Ship
      rs.id.should == rship2.id
    }.should_not raise_error

    rship2.notification_callbacks.size.should == 0
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to move_entity within a system" do
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200', :x => 0, :y => 0, :z => 0)
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201', :x => 0, :y => 0, :z => 0)
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100', :x => 0, :y => 0, :z => 0)
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '150', :x => 0, :y => 0, :z => 0)
    new_loc = Motel::Location.new(:id => 101, :parent_id => sys1.id, :x => 1, :y => 0, :z => 0)
    u = TestUser.create.login(@local_node).clear_privileges

    gal1.add_child(sys1)
    ship1.parent = sys1
    stat1.parent = sys1
    ship1.location.parent = sys1.location
    stat1.location.parent = sys1.location

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run ship1.location
    Cosmos::Registry.instance.add_child gal1
    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create stat1

    lambda{
      @local_node.invoke_request('manufactured::move_entity', 'non_existant', new_loc)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    new_loc.parent_id = 'non_existant'

    lambda{
      @local_node.invoke_request('manufactured::move_entity', ship1.id, new_loc)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    new_loc.parent_id = sys1.id

    lambda{
      @local_node.invoke_request('manufactured::move_entity', ship1.id, new_loc)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'manufactured_entities')

    #lambda{ # TODO try w/ id of fleet
    #  @local_node.invoke_request('manufactured::move_entity', stat1.id, new_loc)
    ##}.should raise_error(ArgumentError)
    #}.should raise_error(Exception)

    new_loc.parent_id = gal1.name

    lambda{
      @local_node.invoke_request('manufactured::move_entity', ship1.id, new_loc)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    new_loc.parent_id = sys1.location.id

    lambda{
      rship = @local_node.invoke_request('manufactured::move_entity', ship1.id, new_loc)
      rship.class.should == Manufactured::Ship
      rship.id.should == ship1.id
    }.should_not raise_error

    # verify ship is now moving using a linear movement strategy towards new location
    rloc = Motel::Runner.instance.locations.find { |l| l.id == ship1.location.id }
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Linear
    rloc.movement_strategy.direction_vector_x.should == 1
    rloc.movement_strategy.direction_vector_y.should == 0
    rloc.movement_strategy.direction_vector_z.should == 0
    rloc.movement_callbacks.size.should == 1

    sleep 2

    # verify ship has arrived and is no longer moving
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Stopped
    rloc.movement_callbacks.size.should == 0
    (rloc.x - new_loc.x).should < 25 # FIXME since the entity is moved in increments of speed, might not be exactly on
    rloc.y.should == new_loc.y
    rloc.z.should == new_loc.z

    rship = Manufactured::Registry.instance.find(:id => ship1.id)
    rship.first.location.x.should == rloc.x
    rship.first.location.y.should == rloc.y
    rship.first.location.z.should == rloc.z
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to move_entity between systems" do
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100', :x => 0, :y => 0, :z => 0)
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '150', :x => 0, :y => 0, :z => 0)
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200', :x => 0, :y => 0, :z => 0)
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201', :x => 0, :y => 0, :z => 0)
    sys2  = Cosmos::SolarSystem.new :name => 'sys2', :location => Motel::Location.new(:id => '202', :x => 0, :y => 0, :z => 0)
    new_loc = Motel::Location.new(:id => 101, :parent_id => sys2.location.id, :x => 10, :y => 0, :z => 0)
    u = TestUser.create.login(@local_node).clear_privileges

    gal1.add_child(sys1)
    gal1.add_child(sys2)
    ship1.parent = sys1
    stat1.parent = sys1

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run sys2.location
    Motel::Runner.instance.run ship1.location
    Cosmos::Registry.instance.add_child gal1
    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create stat1

    ship1.location.movement_callbacks << Motel::Callbacks::Movement.new(:endpoint => Manufactured::RJRAdapter.send(:class_variable_get, :@@local_node).node_id)

    lambda{
      @local_node.invoke_request('manufactured::move_entity', 'non_existant', new_loc)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    new_loc.parent_id = 'non_existant'

    lambda{
      @local_node.invoke_request('manufactured::move_entity', ship1.id, new_loc)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    new_loc.parent_id = sys2.id

    lambda{
      @local_node.invoke_request('manufactured::move_entity', ship1.id, new_loc)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'manufactured_entities')

    lambda{
      @local_node.invoke_request('manufactured::move_entity', stat1.id, new_loc)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    new_loc.parent_id = gal1.id

    lambda{
      @local_node.invoke_request('manufactured::move_entity', ship1.id, new_loc)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    new_loc.parent_id = sys2.location.id

    lambda{
      rship = @local_node.invoke_request('manufactured::move_entity', ship1.id, new_loc)
      rship.class.should == Manufactured::Ship
      rship.id.should == ship1.id
      rship.parent.name.should == sys2.name
    }.should_not raise_error

    # verify ship is now in the new system
    rloc = Motel::Runner.instance.locations.find { |l| l.id == ship1.location.id }
    rloc.movement_strategy.class.should == Motel::MovementStrategies::Stopped
    rloc.parent_id.should == sys2.location.id
    rloc.movement_callbacks.size.should == 0
    rloc.proximity_callbacks.size.should == 0
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to follow_entity" do
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :location => Motel::Location.new(:id => '100', :x => 0, :y => 0, :z => 0)
    ship2 = Manufactured::Ship.new :id => 'ship2', :user_id => 'user1', :location => Motel::Location.new(:id => '150', :x => 0, :y => 0, :z => 0)
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :location => Motel::Location.new(:id => '170', :x => 0, :y => 0, :z => 0)
    gal1  = Cosmos::Galaxy.new :name => 'gal1', :location => Motel::Location.new(:id => '200', :x => 0, :y => 0, :z => 0)
    sys1  = Cosmos::SolarSystem.new :name => 'sys1', :location => Motel::Location.new(:id => '201', :x => 0, :y => 0, :z => 0)
    u = TestUser.create.login(@local_node).clear_privileges

    gal1.add_child(sys1)
    ship1.parent = sys1
    ship2.parent = sys1
    stat1.parent = sys1

    Motel::Runner.instance.run gal1.location
    Motel::Runner.instance.run sys1.location
    Motel::Runner.instance.run ship1.location
    Motel::Runner.instance.run ship2.location
    Motel::Runner.instance.run stat1.location
    Cosmos::Registry.instance.add_child gal1
    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create ship2
    Manufactured::Registry.instance.create stat1

    lambda{
      @local_node.invoke_request('manufactured::follow_entity', 'non_existant', ship2.id, 10)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::follow_entity', ship1.id, 'non_existant', 10)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::follow_entity', ship1.id, ship2.id, 10)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'manufactured_entities')
    u.add_privilege('view', 'manufactured_entities')

    lambda{
      @local_node.invoke_request('manufactured::follow_entity', stat1.id, ship2.id, 10)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::follow_entity', ship1.id, stat1.id, 10)
    #}.should raise_error(ArgumentError)
    }.should raise_error(Exception)

    lambda{
      entity = @local_node.invoke_request('manufactured::follow_entity', ship1.id, ship2.id, 10)
      entity.class.should == Manufactured::Ship
      entity.id.should == ship1.id
    }.should_not raise_error

    ship1.location.movement_strategy.class.should == Motel::MovementStrategies::Follow
    ship1.location.movement_strategy.tracked_location_id.should == ship2.location.id
    ship1.location.movement_strategy.distance.should == 10
  end

  it "should permit users with view manufactured_entities or view manufactured_entity-<id> to attack_entity" do
    sys = Cosmos::SolarSystem.new
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys, :location => Motel::Location.new(:id => '100')
    ship2 = Manufactured::Ship.new :id => 'ship2', :user_id => 'user1', :solar_system => sys, :location => Motel::Location.new(:id => '101')
    u = TestUser.create.login(@local_node).clear_privileges

    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create ship2
    Manufactured::Registry.instance.attack_commands.size.should == 0

    lambda{
      @local_node.invoke_request('manufactured::attack_entity', 'non_existant', ship2.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::attack_entity', ship1.id, 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::attack_entity', ship1.id, ship2.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'manufactured_entities')
    u.add_privilege('view',   'manufactured_entities')

    lambda{
      ships = @local_node.invoke_request('manufactured::attack_entity', ship1.id, ship2.id)
      ships.class.should == Array
      ships.size.should == 2
      ships.first.id.should == ship1.id
      ships.last.id.should  == ship2.id
    }.should_not raise_error

    Manufactured::Registry.instance.attack_commands.size.should == 1
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to start_mining" do
    resource = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
    gal1     = Cosmos::Galaxy.new :name => 'galaxy1'
    sys1     = Cosmos::SolarSystem.new :name => 'system1'
    ast1     = Cosmos::Asteroid.new :name => 'asteroid1'
    ship = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys1, :location => Motel::Location.new(:id => '100')
    u = TestUser.create.login(@local_node).clear_privileges

    Manufactured::Registry.instance.create ship
    Manufactured::Registry.instance.mining_commands.size.should == 0

    Cosmos::Registry.instance.add_child gal1
    gal1.add_child sys1
    sys1.add_child ast1
    rs = Cosmos::Registry.instance.set_resource ast1.name, resource, 50

    lambda{
      @local_node.invoke_request('manufactured::start_mining', ship.id, 'non_existant', resource.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::start_mining', ship.id, ast1.name, 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::start_mining', 'non_existant', ast1.name, resource.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::start_mining', ship.id, ast1.name, resource.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'manufactured_entities')

    lambda{
      rship = @local_node.invoke_request('manufactured::start_mining', ship.id, ast1.name, resource.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == ship.id
      rship.notification_callbacks.size.should == 2
      rship.notification_callbacks.first.type.should == :resource_collected
      rship.notification_callbacks.first.endpoint_id.should == Manufactured::RJRAdapter.send(:class_variable_get, :@@local_node).message_headers['source_node']
      rship.notification_callbacks.last.type.should == :resource_depleted
      rship.notification_callbacks.last.endpoint_id.should == Manufactured::RJRAdapter.send(:class_variable_get, :@@local_node).message_headers['source_node']
    }.should_not raise_error

    Manufactured::Registry.instance.mining_commands.size.should == 1
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to transfer_resource" do
    sys = Cosmos::SolarSystem.new
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys, :location => Motel::Location.new(:id => '100')
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :solar_system => sys, :location => Motel::Location.new(:id => '101')
    resource = Cosmos::Resource.new :type => 'gem', :name => 'diamond'
    u = TestUser.create.login(@local_node).clear_privileges

    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create stat1

    ship1.add_resource resource.id, 50

    lambda{
      @local_node.invoke_request('manufactured::transfer_resource', 'non_existant', stat1.id, resource.id, 10)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::transfer_resource', ship1.id, 'non_existant', resource.id, 10)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::transfer_resource', ship1.id, stat1.id, resource.id, 10)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'manufactured_entity-' + ship1.id)

    lambda{
      @local_node.invoke_request('manufactured::transfer_resource', ship1.id, stat1.id, resource.id, 10)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'manufactured_entity-' + stat1.id)

    nres = Cosmos::Resource.new :type => 'gem', :name => 'ruby'

    lambda{
      @local_node.invoke_request('manufactured::transfer_resource', ship1.id, stat1.id, nres.id, 10)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::transfer_resource', ship1.id, stat1.id, resource.id, 1000)
    #}.should raise_error(Omega::OperationError)
    }.should raise_error(Exception)

    lambda{
      ret = @local_node.invoke_request('manufactured::transfer_resource', ship1.id, stat1.id, resource.id, 10)
      ret.class.should == Array
      ret.size.should == 2
      ret.first.id.should == ship1.id
      ret.last.id.should  == stat1.id
    }.should_not raise_error

    ship1.resources[resource.id].should == 40
    stat1.resources[resource.id].should == 10

    lambda{
      ret = @local_node.invoke_request('manufactured::transfer_resource', stat1.id, ship1.id, resource.id, 5)
      ret.class.should == Array
      ret.size.should == 2
      ret.first.id.should == stat1.id
      ret.last.id.should  == ship1.id
    }.should_not raise_error

    ship1.resources[resource.id].should == 45
    stat1.resources[resource.id].should == 5
  end

  it "should permit users with modify manufactured_entities or modify manufactured_entity-<id> to dock/undock to stations" do
    sys = Cosmos::SolarSystem.new
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys, :location => Motel::Location.new(:id => '100')
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :solar_system => sys, :location => Motel::Location.new(:id => '101')
    u = TestUser.create.login(@local_node).clear_privileges

    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create stat1

    lambda{
      @local_node.invoke_request('manufactured::dock', 'non_existant', stat1.id)
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::dock', ship1.id, 'non_existant')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    lambda{
      @local_node.invoke_request('manufactured::dock', ship1.id, stat1.id)
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    u.add_privilege('modify', 'manufactured_entities')

    lambda{
      rship = @local_node.invoke_request('manufactured::dock', ship1.id, stat1.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == ship1.id
      rship.docked?.should be_true
      rship.docked_at.id.should == stat1.id
    }.should_not raise_error

    lambda{
      rship = @local_node.invoke_request('manufactured::undock', ship1.id)
      rship.class.should == Manufactured::Ship
      rship.id.should == ship1.id
      rship.docked?.should be_false
      rship.docked_at.should be_nil
    }.should_not raise_error
  end

  it "should permit local nodes to save and restore state" do
    sys = Cosmos::SolarSystem.new
    ship1 = Manufactured::Ship.new :id => 'ship1', :user_id => 'user1', :solar_system => sys, :location => Motel::Location.new(:id => '100')
    stat1 = Manufactured::Station.new :id => 'station1', :user_id => 'user1', :solar_system => sys, :location => Motel::Location.new(:id => '101')
    stat2 = Manufactured::Station.new :id => 'station2', :user_id => 'user1', :solar_system => sys, :location => Motel::Location.new(:id => '102')
    u = TestUser.create.login(@local_node).clear_privileges

    Manufactured::Registry.instance.create ship1
    Manufactured::Registry.instance.create stat1
    Manufactured::Registry.instance.create stat2
    Manufactured::Registry.instance.ships.size.should == 1
    Manufactured::Registry.instance.stations.size.should == 2

    lambda{
      ret = @local_node.invoke_request('manufactured::save_state', '/tmp/manufactured-test')
      ret.should be_nil
    }.should_not raise_error

    Manufactured::Registry.instance.init
    Manufactured::Registry.instance.ships.size.should == 0
    Manufactured::Registry.instance.stations.size.should == 0

    lambda{
      ret = @local_node.invoke_request('manufactured::restore_state', '/tmp/manufactured-test')
      ret.should be_nil
    }.should_not raise_error

    Manufactured::Registry.instance.ships.size.should == 1
    Manufactured::Registry.instance.ships.first.id.should == ship1.id
    Manufactured::Registry.instance.stations.size.should == 2
    Manufactured::Registry.instance.stations.first.id.should == stat1.id
    Manufactured::Registry.instance.stations.last.id.should  == stat2.id

    FileUtils.rm_f '/tmp/manufactured-test'
  end
end
