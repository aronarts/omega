# Missions Resources Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# TODO some way of capping this / conditionalizing to halt or
# temporarily stop at some point, eg if an asteroid, system or
# universe has the max resources, etc

# TODO perhaps make this a command instead of an event?

require 'omega/server/event'
require 'missions/rjr/init'

module Missions
module Events

# An event to populate the specified cosmos entity w/ the specified resource
class PopulateResource < Omega::Server::Event

  # Default quantity of resource that will be added if not specified
  DEFAULT_QUANTITY = 1000

  # Resource which to populate or random
  attr_accessor :resource

  # List of resources which to pick random resource from
  attr_accessor :from_resources

  # Entity which to populate or random
  attr_accessor :entity

  # List of entities which to pick random entity from
  attr_accessor :from_entities

  # Quantity which to populate or random
  attr_accessor :quantity

  private

  # Handle event, generate resource
  def handle_event
    @resource = @resource == :random ?
                from_resources[rand(from_resources.size)] :
                @resource

    @entity   = @entity   == :random ?
                from_entities[rand(from_entities.size)] :
                @entity

    @quantity = @quantity == :random ?
                rand(DEFAULT_QUANTITY) :
                @quantity

    @resource.id        = Motel.gen_uuid
    @resource.entity_id = @entity.id
    @resource.quantity  = @quantity
    Missions::RJR.node.invoke('cosmos::set_resource', @resource)
  end

  public

  # PopulateResource Event Initializer
  def initialize(args = {})
    attr_from_args args,
                   :resource => :random,
                   :entity   => :random,
                   :quantity => :random,
                   :from_entities  => [],
                   :from_resources => []

    [:@resource, :@entity, :@quantity].each { |a|
      v = self.instance_variable_get(a)
      self.instance_variable_set(a, v.intern) if v == 'random'
    }

    super(args)
    @handlers.unshift  proc { |e| handle_event }
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        json_data.merge({:handlers => handlers[1..-1],
                         :resource => resource,
                         :entity => entity,
                         :quantity => @quantity,
                         :from_entities => @from_entities,
                         :from_resources => @from_resources})
    }.to_json(*a)
  end
end

end
end
