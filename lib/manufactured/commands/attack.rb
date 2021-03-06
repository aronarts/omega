# Manufactured attack command definition
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'
require 'omega/server/command'
require 'omega/server/command_helpers'

require 'manufactured/events/entity_destroyed'

module Manufactured
module Commands

# Represents action of one {Manufactured::Ship} attacking another
#
# Registered with the registry by a client when attacker commences
# attacking and periodically run by registry until attacked stops,
# defender is destroyed, or one of several other conditions occur.
#
# Invokes {Omega::Server::Callback}s registered with the attacker
# and defender before/during/after the attack cycle with the event type,
# the attacking ship, and the defending ship as params
#
# The callback events/types invoked include:
# * 'attacked_stop' - invoked on the attacker when attacker stops attacking
# * 'defended_stop' - invoked on the defender when attacker stops attacking
# * 'attacked'      - invoked on the attacker when attacker actually launches the attack
# * 'defended'      - invoked on the defender when attacker actually launches the attack
# * 'destroyed'     - invoked on the defender if this attack cycle resulted in the defender hp becoming <= 0
class Attack < Omega::Server::Command
  include Omega::Server::CommandHelpers

  # {Manufactured::Ship} performing the attack
  attr_accessor :attacker

  # {Manufactured::Ship} receiving that attack
  attr_accessor :defender

  # Return the unique id of this attack command.
  #
  # Currently a ship may only attack one other at a time,
  # TODO incorporate multiple weapons and area based weapons
  # (multiple defenders) into this
  def id
    id = @attacker.nil? ? "" : @attacker.id.to_s
    "attack-cmd-#{id}"
  end

  def processes?(entity)
    entity.is_a?(Manufactured::Ship) &&
    (entity.id == attacker.id || entity.id == defender.id)
  end

  # Manufactured::Commands::Attack initializer
  # @param [Hash] args hash of options to initialize attack command with
  # @option args [Manufactured::Ship] :attacker ship attacking the defender
  # @option args [Manufactured::Ship] :defender ship receiving attack from the attacker
  def initialize(args = {})
    attr_from_args args, :attacker => nil,
                         :defender => nil
    super(args)
  end

  private

  def refresh_entities
    # update entities from registry
    @attacker = retrieve(@attacker.id)
    @defender = retrieve(@defender.id)
  end

  def refresh_locations
    # update locations from motel
    @attacker.location = invoke 'motel::get_location',
                                'with_id', @attacker.location.id
    @defender.location = invoke 'motel::get_location',
                                'with_id', @defender.location.id
  end

  def start_attack
    @attacker.start_attacking(@defender)
    update_registry(@attacker, :attacking)
  end

  def stop_attack
    @attacker.stop_attacking
    update_registry(@attacker, :attacking)
    ::RJR::Logger.info "#{@attacker.id} stopped attacking #{@defender.id}"
  end

  def run_completion_callbacks
    # invoke attackers's 'attacked_stop' callbacks
    run_callbacks(@attacker, 'attacked_stop', @defender)

    # invoke defender's 'defended_stop' callbacks
    run_callbacks(@defender, 'defended_stop', @attacker)

    # invoke defender's 'destroyed' callbacks
    destroyed_by_attacker = !@defender.alive? && @defender.destroyed_by_id == @attacker.id
    run_callbacks(@defender, 'destroyed_by', @attacker) if destroyed_by_attacker
  end

  def update_locations
    # only need to update defender for now
    # update ship's movement strategy to stopped
    @defender.location.movement_strategy = Motel::MovementStrategies::Stopped.instance
    invoke("motel::update_location", @defender.location)

    # TODO issue call to motel to lock destroyed ship's location
    # (when that operation is supported)
  end

  def update_attributes
    invoke('users::update_attribute', @attacker.user_id,
           Users::Attributes::ShipsUserDestroyed.id,  1)
    invoke('users::update_attribute', @defender.user_id,
           Users::Attributes::UserShipsDestroyed.id,  1)
  end

  def create_loot
    return if @defender.cargo_empty?

    # two entities (ship/loot) sharing same location
    loot = Manufactured::Loot.new :id => "#{@defender.id}-loot",
             :location          => @defender.location,
             :system_id         => @defender.system_id,
             :movement_strategy => Motel::MovementStrategies::Stopped.instance,
             :cargo_capacity    => @defender.cargo_capacity
    @defender.resources.each { |r| loot.add_resource r }
    registry << loot
  end

  def register_destroyed_event
    event = Manufactured::Events::EntityDestroyed.new(:entity => @defender)
    registry << event
  end

  # Invoked when defender is destroyed
  def cleanup_defender
    ::RJR::Logger.info "#{@attacker.id} destroyed #{@defender.id}"

    update_locations

    # Stop commands related to destroyed ship.
    # All commands should auto-stop if related entity is not alive
    # but this stops the commands immediately so that it's done w/
    registry.stop_commands_for(@defender)

    # set user attributes
    update_attributes

    # create loot if necessary
    create_loot

    # Dispatch new entity_destroyed event to registry
    register_destroyed_event
  end

  public

  def first_hook
    refresh_entities
    start_attack
  end

  def before_hook
    refresh_entities
    refresh_locations
  end

  def after_hook
    # persist entities to the registry
    #update_registry(@attacker)
    update_registry(@defender, :hp, :shield_level, :destroyed_by)
  end

  def last_hook
    stop_attack
    cleanup_defender unless @defender.alive?
    run_completion_callbacks
  end

  def stop_hook
    refresh_entities
    return unless @attacker.attacking? # catches the command which stops others
                                       # so that cb's are not run twice
    stop_attack
    run_completion_callbacks
  end

  def should_run?
    super && @attacker.can_attack?(@defender)
  end

  def run!
    super
    ::RJR::Logger.debug "invoking attack command #{@attacker.id} -> #{@defender.id}"

    # TODO incorporate a hit / miss probability into this
    # TODO incorporate AC / other defense mechanisms into this
    # TODO delay between launching attack and it arriving at defender
    #   (depending on distance and projectile speed)

    # first reduce defender's shield then hp
    if @attacker.damage_dealt <= @defender.shield_level
      @defender.shield_level -= @attacker.damage_dealt

    else
      pips = (@attacker.damage_dealt - @defender.shield_level)
      @defender.hp -= pips
      @defender.shield_level = 0

      if @defender.hp <= 0
        @defender.hp = 0
        @defender.destroyed_by = @attacker
      end
    end

    # invoke attacker's 'attacked' callbacks
    run_callbacks(@attacker, 'attacked', @defender)

    # invoke defender's 'defended' callbacks
    run_callbacks(@defender, 'defended', @attacker)
  end

  def remove?
    # remove if defender is destroyed
    @defender.hp == 0 || !@attacker.can_attack?(@defender)
  end

   # Convert command to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:attacker => attacker,
          :defender => defender}.merge(cmd_json)
     }.to_json(*a)
   end

end # class Attack
end # module Commands
end # module Manufactured
