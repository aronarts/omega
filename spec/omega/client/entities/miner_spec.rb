# Omega Client Miner Tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/miner'

module Omega::Client
  describe Miner, :rjr => true do
    before(:each) do
      Omega::Client::Miner.node.rjr_node = @n
      @m = Omega::Client::Miner.new

      setup_manufactured(nil, reload_super_admin)
    end

    describe "#validatation" do
      it "ensures ship.type == :mining" do
        s1 = create(:valid_ship, :type => :mining)
        s2 = create(:valid_ship, :type => :frigate)
        r = Miner.get_all
        r.size.should == 1
        r.first.id.should == s1.id
      end
    end

    describe "#cargo_full" do
      before(:each) do
        s = create(:valid_ship, :type => :mining)
        @r = Miner.get(s.id)
      end

      context "entity cargo full" do
        it "sets entity to :cargo_full state" do
          @r.should_receive(:cargo_full?).and_return(true)
          @r.should_receive :offload_resources
          @r.raise_event(:anything)
          @r.states.should include(:cargo_full)
        end

        it "offloads resources" do
          @r.should_receive(:cargo_full?).and_return(true)
          @r.should_receive :offload_resources
          @r.raise_event(:anything)
        end
      end

      context "entity cargo not full" do
        it "removes entity from :cargo_full state" do
          @r.should_receive(:cargo_full?).and_return(false)
          @r.raise_event(:anything)
          @r.states.should_not include(:cargo_full)
        end
      end
    end

    describe "#mine" do
      before(:each) do
        s = create(:valid_ship, :type => :mining)
        @rs = create(:resource)
        @r = Miner.get(s.id)
      end

      context "resource collected" do
        it "TODO"
      end

      it "invokes manufactured::start_mining" do
        @n.should_receive(:invoke).with 'manufactured::start_mining', @r.id, @rs.id
        @r.mine @rs
      end

      it "updates local entity"
    end

    describe "#start_bot" do
      before(:each) do
        s = create(:valid_ship, :type => :mining)
        @r = Miner.get(s.id)
      end

      it "starts listening for resource_collected events"

      it "adds mining stopped handler" do
        @r.event_handlers[:mining_stopped].size.should == 0
        @r.start_bot
        @r.event_handlers[:mining_stopped].size.should == 1
      end

      context "cargo full" do
        it "offloads resources" do
          @r.should_receive(:cargo_full?).and_return(true)
          @r.should_receive(:offload_resources)
          @r.start_bot
        end
      end

      context "cargo not full" do
        it "selects mining target" do
          @r.should_receive(:cargo_full?).and_return(false)
          @r.should_receive(:select_target)
          @r.start_bot
        end
      end
    end

    describe "#offload_resources" do
      before(:each) do
        s = create(:valid_ship, :type => :mining, :transfer_distance => 50,
                   :location => build(:location, :x => 0, :y => 0, :z => 0))
        @r = Miner.get(s.id)
      end

      it "selects closest station" do
        s = create(:valid_station, :location => @r.location)
        @r.should_receive(:closest).with(:station).and_return([s])
        @r.should_receive(:select_target)
        @r.offload_resources
      end

      context "station is nil" do
        it "raises :no_stations event"
        it "returns"
      end

      context "closest station is within transfer distance" do
        it "transfers resources" do
          s = create(:valid_station, :location => @r.location)
          @r.should_receive(:closest).with(:station).and_return([s])
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.offload_resources
        end

        context "error during transfer" do
          it "refreshes stations"
          it "retries resource offloading twice"
          context "all transfer retries fail" do
            it "raises transfer_err event"
            it "returns"
          end
        end

        it "selects mining target" do
          s = create(:valid_station, :location => @r.location)
          @r.should_receive(:closest).with(:station).and_return([s])
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:select_target)
          @r.offload_resources
        end
      end

      it "moves to closest station" do
        s = create(:valid_station, :location => @r.location + [100,0,0])
        @r.should_receive(:closest).with(:station).and_return([s])
        @r.should_receive(:move_to).with(:destination => s)
        @r.offload_resources
      end

      it "raises moving_to event" do
        s = create(:valid_station, :location => @r.location + [100,0,0])
        @r.should_receive(:closest).with(:station).and_return([s])
        @r.should_receive(:raise_event).with(:moving_to, s)
        @r.offload_resources
      end

      context "arrived at closest station" do
        it "transfers resources" do
          s = create(:valid_station, :location => @r.location + [100,0,0])
          @r.should_receive(:closest).with(:station).twice.and_return([s])
          @r.offload_resources
          s.location.x = 0
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.raise_event(:movement)
        end

        it "selects mining target" do
          s = create(:valid_station, :location => @r.location + [100,0,0])
          @r.should_receive(:closest).with(:station).twice.and_return([s])
          @r.offload_resources
          s.location.x = 0
          @r.should_receive(:transfer_all_to).with(s)
          @r.should_receive(:select_target)
          @r.raise_event(:movement)
        end
      end

      context "error during resource transfer" do
        it "retries offload_resources"
      end
    end

    describe "#select_target" do
      before(:each) do
        s = create(:valid_ship, :type => :mining,
                   :location => build(:location, :x => 0, :y => 0, :z => 0))
        @r = Miner.get(s.id)

        @cast = create(:asteroid,
                       :location => build(:location, :coordinates => [0,0,0]))
        @cres = create(:resource, :entity => @cast, :quantity => 10)
        @cast.set_resource @cres

        @fast = create(:asteroid,
                       :location => build(:location, :coordinates => [s.mining_distance+100,0,0]))
        @fres = create(:resource, :entity => @fast, :quantity => 10)
        @fast.set_resource @fres
      end

      it "selects closest resource" do
        @r.should_receive(:closest).with(:resource).and_return([])
        @r.select_target
      end

      context "no resources found" do
        it "raises no_resources event" do
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.should_receive(:raise_event).with(:no_resources)
          @r.select_target
        end

        it "just returns" do
          @r.should_receive(:closest).with(:resource).and_return([])
          @r.should_not_receive(:move_to)
          @r.should_not_receive(:mine)
          @r.select_target
        end
      end

      it "raises selected_resource event" do
        @r.should_receive(:closest).with(:resource).and_return([@cast])
        @r.should_receive(:raise_event).with(:selected_resource, @cast)
        @r.select_target
      end

      context "closest resource withing mining distance" do
        it "starts mining resource" do
          @r.should_receive(:closest).with(:resource).and_return([@cast])
          @r.should_receive(:mine).with(@cres)
          @r.select_target
        end
      end

      #context "error during mining" do
      #  it "selects mining target" do
      #    @r.should_receive(:closest).with(:resource).and_return([@cast])
      #    @r.should_receive(:mine).with(@cres).and_raise(Exception)
      #    @r.should_receive(:select_target) # XXX
      #    @r.select_target
      #  end
      #end

      it "moves to closes resource" do
        @r.should_receive(:closest).with(:resource).and_return([@fast])
        @r.should_receive(:move_to)
        @r.select_target
      end

      context "arrived at closest resource" do
        it "starts mining resource" do
          @r.should_receive(:closest).with(:resource).and_return([@fast])
          @r.select_target
          @r.should_receive(:mine).with(@fres)
          @r.raise_event :movement
        end

      #  context "error during mining" do
      #    it "selects mining target" do
      #    @r.should_receive(:closest).with(:resource).and_return([@fast])
      #    @r.select_target
      #    @r.should_receive(:mine).with(@fast).and_raise(Exception)
      #    @r.should_receive(:select_target)
      #    @r.raise_event :movement
      #    end
      #  end
      end
    end

  end # describe Miner
end # module Omega::Client
