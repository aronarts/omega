# Omega Server Command tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/command'

#require 'timecop'
#Timecop.return
#Timecop.freeze

module Omega
module Server

describe Command do
  describe "#processes?" do
    it "does not process anything by default" do
      Command.new.processes?("anything").should be_false
    end
  end

  describe "#initialize" do
    it "sets defaults" do
      c = Command.new
      c.id.should be_nil
      c.exec_rate.should be_nil
      c.last_ran_at.should be_nil
      c.ran_first_hooks.should be_false
      [:first, :before, :after, :last].each { |h|
        c.hooks[h].should_not be_empty
      }
    end

    it "sets attributes" do
      c = Command.new :id => :foo,
                      :exec_rate => 5,
                      :hooks  => [:foobar]
      c.id.should == :foo
      c.exec_rate.should == 5
      c.hooks.should == [:foobar]
    end
  end

  describe "#update" do
    it "updates cmd :ran_first_hooks" do
      c1 = Command.new
      c2 = Command.new :ran_first_hooks => true
      c1.update c2
      c1.ran_first_hooks.should be_true
    end

    it "updates cmd :last_ran_at" do
      c1 = Command.new
      c2 = Command.new :last_ran_at => Time.now
      c1.update c2
      c1.last_ran_at.should == c2.last_ran_at
    end

    it "updates cmd :exec_rate" do
      c1 = Command.new
      c2 = Command.new :exec_rate => 5
      c1.update c2
      c1.exec_rate.should == 5
    end

    it "ignores other attributes" do
      c1 = Command.new
      c2 = Command.new :id => 'foo'
      c1.update c2
      c1.id.should be_nil
    end
  end

  describe "run_hooks" do
    it "runs hooks of the specified type" do
      c = Command.new
      c.should_receive :first_hook
      c.run_hooks(:first)
    end

    context "hook == first" do
      it "sets ran_first_hooks" do
        c = Command.new
        c.run_hooks(:first)
        c.ran_first_hooks.should be_true
      end
    end
  end

  describe "#should_run?" do
    context "last ran at == nil" do
      it "returns true" do
        c = Command.new :exec_rate => 5
        c.instance_variable_set(:@last_ran_at, nil)
        c.should_run?.should be_true
      end
    end

    context "exec rate == nil" do
      it "returns true" do
        c = Command.new :exec_rate => nil
        c.instance_variable_set(:@last_ran_at, Time.now)
        c.should_run?.should be_true
      end
    end

    context "interval > exec rate" do
      it "returns true" do
        c = Command.new :exec_rate => 1
        c.instance_variable_set(:@last_ran_at, Time.now - 2)
        c.should_run?.should be_true
      end
    end

    context "interval <= exec rate" do
      it "returns false" do
        c = Command.new :exec_rate => 1
        c.instance_variable_set(:@last_ran_at, Time.now)
        c.should_run?.should be_false
      end
    end
  end

  describe "#run!" do
    it "should set last_ran_at" do
      c = Command.new
      c.run!
      c.last_ran_at.should_not be_nil
      c.last_ran_at.should be_an_instance_of(Time)
    end
  end

  describe "#remove?" do
    it "defaults to false" do
      c = Command.new
      c.remove?.should be_false
    end
  end

  describe "#to_json" do
    it "returns command in json format" do
      t = Time.now
      c = Command.new :id              => :foo,
                      :exec_rate       => 5,
                      :ran_first_hooks => true,
                      :last_ran_at     =>   t
      j = c.to_json
      j.should include('"json_class":"Omega::Server::Command"')
      j.should include('"id":"foo"')
      j.should include('"exec_rate":5')
      j.should include('"last_ran_at":"'+t.to_s+'"')
    end
  end

  describe "#json_create" do
    it "returns command from json format" do
      t = Time.parse '2013-06-16 09:07:19 -0400'
      j = '{"json_class":"Omega::Server::Command","data":{"id":"foo","exec_rate":5,"ran_first_hooks":false,"last_ran_at":"'+t.to_s+'"}}'
      c = RJR::JSONParser.parse j

      c.should be_an_instance_of(Command)
      c.id.should == 'foo'
      c.exec_rate.should == 5
      c.last_ran_at.should == t
    end
  end
end # describe Command
end # module Server
end # module Omega
