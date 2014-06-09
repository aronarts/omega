# client node module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/node'
require 'omega/client/dsl'
require 'rjr/nodes/tcp'

module Omega::Client
describe Node, :rjr => true do
  include Omega::Client::DSL # to log user in

  before(:each) do
    dsl.rjr_node = @n

    @u = reload_super_admin
    login @u.id, @u.password
  end

  describe "#rjr_node=" do
    it "sets rjr node" do
      n = Node.new
      n.rjr_node = @n
      n.rjr_node.should == @n
    end

    it "sets rjr node headers" do
      n = Node.new
      n.rjr_node = @n
      @n.message_headers['source_node'].should == @n.node_id
    end

    it "sets endpoint" do
      n = Node.new
      @n = RJR::Nodes::TCP.new
      n.rjr_node = @n
      n.endpoint.should == 'jsonrpc://localhost:8181'
    end
  end

  describe "#invoke" do
    it "invokes method to endpoint using node" do
      n = Node.new
      n.rjr_node = @n
      args = ['users::get_entity', 'with_id', @u.id]
      @n.should_receive(:invoke).with(*args).and_call_original
      u = n.invoke(*args)
      u.should be_an_instance_of(Users::User)
      u.id.should == @u.id
    end
  end

  describe "#notify" do
    it "sends notification to endpoint using node" do
      n = Node.new
      n.rjr_node = @n
      args = ['users::get_entity', 'with_id', @u.id]
      @n.should_receive(:notify).with(*args).and_call_original
      n.notify(*args)
    end
  end

  describe "#handles?" do
    context "node handles event" do
      it "returns true" do
        n = Node.new
        n.rjr_node = @n
        n.handle(:foo) { }
        n.handles?(:foo).should be_true
      end
    end

    context "node does not handle event" do
      it "returns false" do
        n = Node.new
        n.rjr_node = @n
        n.handles?(:foo).should be_false
      end
    end
  end

  describe "#handle" do
    it "registers handler for specified method" do
      n = Node.new
      n.rjr_node = @n
      handler = proc {}
      n.handle('foo', &handler)
      n.handlers['foo'].should == [handler]
    end

    context "first handler for specified method" do
      it "registers method w/ rjr dispathcer" do
        n = Node.new
        n.rjr_node = @n
        handler = proc {}
        @n.dispatcher.handlers['foo'].should be_nil
        n.handle('foo', &handler)
        @n.dispatcher.handlers['foo'].should_not be_nil
      end
    end

    context "rjr method invoked" do
      before(:each) do
        @node = Node.new
        @node.rjr_node = @n
      end

      it "runs all registered handlers" do
        handler = proc {}
        @node.handle 'foo', &handler
        handler.should_receive(:call).with(42)
        @n.invoke 'foo', 42
      end

      # not implemented in code yet
      #it "discards errors in event handlers" do
      #  handler = proc { raise Exception }
      #  @node.handle 'foo', &handler
      #  handler.should_receive(:call).and_call_original
      #  lambda {
      #    @n.invoke 'foo', 42
      #  }.should_not raise_error
      #end

      it "returns nil" do
        handler = proc {}
        @node.handle 'foo', &handler
        @n.invoke('foo', 42).should be_nil
      end
    end
  end

end # describe Node
end # module Omega::Client

#describe Omega::Client::CachedAttribute do
#  before(:each) do
#    @old = CachedAttribute::TIMEOUT
#    CachedAttribute::TIMEOUT = 1
#
#    $times_invoked = 0
#    $te = OmegaTest::Entity.new
#    CachedAttribute.cache($te, :attr) { |ta|
#      self.id.should == $te.id
#      $times_invoked += 1
#      ta + 1
#    }
#  end
#
#  after(:each) do
#    CachedAttribute::TIMEOUT = @old
#  end
#
#  it "should cache entity attribute" do
#    $te.attr.should == 1
#    $times_invoked.should == 1
#    $te.attr.should == 1
#    $times_invoked.should == 1
#
#    sleep 1.1
#    $te.attr.should == 2
#    $times_invoked.should == 2
#  end
#
#  it "should be globally toggable" do
#    CachedAttribute.enabled?.should == true
#    CachedAttribute.enabled?(false)
#    CachedAttribute.enabled?.should == false
#
#    $te.attr.should == 0
#    $times_invoked.should == 0
#
#    CachedAttribute.enabled?(true)
#    CachedAttribute.enabled?.should == true
#  end
#
#  # TODO test invalidation
#  it "should permit entity attribute invalidation" do
#    $te.attr.should == 1
#    $times_invoked.should == 1
#    $te.attr.should == 1
#    $times_invoked.should == 1
#    CachedAttribute.invalidate($te.id, :attr)
#    $te.attr.should == 2
#    $times_invoked.should == 2
#  end
#
#end
