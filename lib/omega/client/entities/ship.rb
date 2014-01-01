# Omega client ship tracker
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO event rate throttling mechanisms:
#   - after threshold only process 1 out of every n events in raise_event
#   - flush queue if max events reached in raise_event
#   - delay new request until events go below threshold in invoke_request
#   - stop running actions on server side until queue is completed, then restart
#   - overwrite pending entity events w/ new events of the same type

require 'omega/client/mixins'
require 'omega/client/entities/location'
require 'omega/client/entities/cosmos'
require 'omega/client/entities/station'
require 'manufactured/ship'

module Omega
  module Client
    # Omega client Manufactured::Ship tracker
    class Ship
      include Trackable
      include TrackEntity
      include TrackState
      include HasLocation
      include InSystem
      include HasCargo

      entity_type  Manufactured::Ship

      get_method   "manufactured::get_entity"

      entity_event \
        :defended =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'defended' && a[1].id == entity.id },
            :update => proc { |entity, *a|
              entity.hp,entity.shield_level =
                a[1].hp, a[1].shield_level
            }},

        :defended_stop =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'defended_stop' && a[1].id == entity.id },
            :update => proc { |entity, *a|
              entity.hp,entity.shield_level =
                a[1].hp, a[1].shield_level
            }},

        :destroyed_by =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'destroyed' && a[1].id == entity.id },
            :update => proc { |entity, *a|
              entity.hp,entity.shield_level =
                a[1].hp, a[1].shield_level
            }}

      # automatically cleanup entity when destroyed
      server_state :destroyed,
        :check => lambda { |e| !e.alive? },
        :off   => lambda { |e| },
        :on    =>
          lambda { |e|
            # TODO remove rjr notifications
            e.clear_handlers
          }

      # Dock at the specified station
      def dock_to(station)
        RJR::Logger.info "Docking #{id} at #{station.id}"
        node.invoke 'manufactured::dock', id, station.id
      end

      # Undock
      def undock
        RJR::Logger.info "Unocking #{id}"
        node.invoke 'manufactured::undock', id
      end

      # Collect specified loot
      #
      # @param [Manufactured::Loot] loot loot which to collect
      def collect_loot(loot)
        RJR::Logger.info "Entity #{id} collecting loot #{loot.id}"
        @entity = node.invoke 'manufactured::collect_loot', id, loot.id
      end
    end

    # Omega client miner ship tracker
    class Miner < Ship
      entity_validation { |e| e.type == :mining }

      entity_event \
        :resource_collected =>
          {:subscribe    => "manufactured::subscribe_to",
           :notification => "manufactured::event_occurred",
           :match => proc { |entity,*a|
             a[0] == 'resource_collected' &&
             a[1].id == entity.id },
           :update => proc { |entity, *a|
             rs = a[2] ; rs.quantity = a[3]
             entity.add_resource rs
           }},

        :mining_stopped     =>
          {:subscribe    => "manufactured::subscribe_to",
           :notification => "manufactured::event_occurred",
           :match => proc { |entity,*a|
             a[0] == 'mining_stopped' &&
             a[1].id == entity.id
           },
           :update => proc { |entity,*a|
             #entity.entity = a[1] # may contain resources already removed
             entity.stop_mining
           }}

      server_state :cargo_full,
        :check => lambda { |e| e.cargo_full?       },
        :on    => lambda { |e| e.offload_resources },
        :off   => lambda { |e| }

      # Mine the specified resource
      #
      # All server side mining restrictions apply, this method does
      # not do any checks b4 invoking start_mining so if server raises
      # a related error, it will be reraised here
      #
      # @param [Cosmos::Resource] resource to start mining
      def mine(resource)
        RJR::Logger.info "Starting to mine #{resource.material_id} with #{id}"
        @entity = node.invoke 'manufactured::start_mining', id, resource.id
      end

      # Start the omega client bot
      def start_bot
        # start listening for events which may trigger state changes
        handle(:resource_collected)
        handle(:mining_stopped) { |m,*args|
          m.select_target if args[3] != 'ship_cargo_full'
        }

        if cargo_full?
          offload_resources
        else
          select_target
        end
      end

      # Move to the closest station owned by user and transfer resources to it
      def offload_resources
        st = closest(:station).first

        if st.nil?
          raise_event(:no_stations)
          return

        elsif st.location - location < transfer_distance
          begin
            transfer_all_to(st)

            # allow two errors before giving up
            @transfer_errs = 0
          rescue Exception => e
            @transfer_errs ||= 0
            @transfer_errs  += 1
            if @transfer_errs > 2
              raise_event(:transfer_err, st)
              return
            end

            # refresh stations and try again
            Omega::Client::Station.refresh
            offload_resources
            return
          end

          select_target

        else
          raise_event(:moving_to, st)
          move_to(:destination => st) { |*args|
            offload_resources
          }
        end
      end

      # Select next resource, move to it, and commence mining
      def select_target
        ast = closest(:resource).first
        if ast.nil?
          raise_event(:no_resources)
          return
        else
          raise_event(:selected_resource, ast)
        end

        rs  = ast.resources.find { |rsi| rsi.quantity > 0 }

        if ast.location - location < mining_distance
          # server resource may by depleted at any point,
          # need to catch errors, and try elsewhere
          begin
            mine(rs)
          rescue Exception => e
            select_target
          end

        else
          dst = mining_distance / 4
          nl  = ast.location + [dst,dst,dst]
          move_to(:location => nl) { |*args|
            begin
              mine(rs)
            rescue Exception => e
              select_target
            end
          }
        end
      end
    end

    # Omega client corvette ship tracker
    class Corvette < Ship
      entity_validation { |e| e.type == :corvette }

      entity_event \
        :attacked =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'attacked' && a[1].id == entity.id
            }},

        :attacked_stop =>
          { :subscribe    => "manufactured::subscribe_to",
            :notification => "manufactured::event_occurred",
            :match => proc { |entity, *a|
              a[0] == 'attacked_stop' && a[1].id == entity.id
            }}

      # Run proximity checks via an external thread for all corvettes
      # upon first corvette intialization
      #
      # TODO introduce a centralized entity tracking cycle
      # via mixin and utilize that here
      entity_init { |corvette|
        @@corvettes ||= []
        @@corvettes << corvette

        @@proximity_thread ||= Thread.new {
          while true
            @@corvettes.each { |c|
              c.check_proximity
            }
            sleep 10
          end
        }
      }

      # Attack the specified target
      #
      # All server side attack restrictions apply, this method does
      # not do any checks b4 invoking attack_entity so if server raises
      # a related error, it will be reraised here
      #
      # @param [Manufactured::Ship,Manufactured::Station] target entity to attack
      def attack(target)
        RJR::Logger.info "Starting to attack #{target.id} with #{id}"
        node.invoke 'manufactured::attack_entity', id, target.id
      end

      # visited systems
      attr_accessor :visited

      # Start the omega client bot
      def start_bot
        handle(:destroyed_by)
        patrol_route
      end

      # Calculate an inter-system route to patrol and move through it.
      def patrol_route
        @visited  ||= []

        # add local system to visited list
        @visited << solar_system unless @visited.include?(solar_system)

        # grab jump gate of a neighboring system we haven't visited yet
        jg = solar_system.jump_gates.find { |jg|
               !@visited.collect { |v| v.id }.include?(jg.endpoint_id)
             }

        # if no items in to_visit clear lists
        if jg.nil?
          # if jg can't be found on two subsequent runs,
          # error out / stop bot
          if @patrol_err
            raise_event(:patrol_err)
            return
          end
          @patrol_err = true

          @visited  = []
          patrol_route

        else
          @patrol_err = false
          raise_event(:selected_system, jg.endpoint_id, jg)
          if jg.location - location < jg.trigger_distance
            jump_to(jg.endpoint)
            patrol_route

          else
            dst = jg.trigger_distance / 4
            nl  = jg.location + [dst,dst,dst]
            move_to(:location => nl) {
              jump_to(jg.endpoint)
              patrol_route
            }
          end
        end
      end

      # Internal helper, check nearby locations, if enemy ship is detected
      # stop movement and attack it. Result patrol route when attack ceases
      def check_proximity
        solar_system.entities.each { |e|
          if e.is_a?(Manufactured::Ship) && e.user_id != user_id &&
             e.location - location <= attack_distance && e.alive?
            stop_moving
            unless @check_proximity_handler
              @check_proximity_handler = true
              handle(:attacked_stop){ |*args| patrol_route }
            end
            attack(e)
            break
          end
        } if self.alive? && !self.attacking?
      end
    end
  end
end
