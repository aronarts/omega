# client location module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/location'

# Test data used in this module
module OmegaTest
  class HasLocation
    include Omega::Client::Trackable
    include Omega::Client::TrackEvents
    include Omega::Client::HasLocation
  end
end

module Omega::Client
  describe HasLocation do
    before(:each) do
      @h = OmegaTest::HasLocation.new
      @h.entity = double(Object, :location => double(Object))

      OmegaTest::HasLocation.node.rjr_node = @n
    end

    describe "#location" do
      it "retrieves location from server" do
        @h.entity.location.should_receive(:id).and_return(42)
        @h.node.should_receive(:invoke).
                with('motel::get_location', 'with_id', 42).and_return(:loc)
        @h.location.should == :loc
      end
    end

    it "creates movement event" do
       @h.class.event_setup[:movement].size.should == 2
    end

    it "creates subscribes client to motel::track_movement" do
      @h.entity.location.should_receive(:id).and_return(42)
      @h.node.should_receive(:invoke).
              with('motel::track_movement', 42, 10)
      @h.handle(:movement, 10)
    end

    it "creates handles motel::on_movement notifications" do
      @h.entity.location.should_receive(:id).and_return(42)
      @h.node.should_receive(:invoke).
              with('motel::track_movement', 42, 10)
      @h.handle(:movement, 10)
      @h.node.handlers['motel::on_movement'].size.should == 1
    end

  end # describe HasLocation

end # module Omega::Client
