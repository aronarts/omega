# Motel rjr adapter
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Motel

class RJRAdapter
  def self.init
    Motel::Runner.instance.start :async => true
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('hello_world') { |location_id|
      puts "Hello World #{location_id}"
      42
    }

    rjr_dispatcher.add_handler('get_location') { |location_id|
       Logger.info "received get location #{location_id} request"
       loc = nil
       begin
         loc = Runner.instance.locations.find { |loc| loc.id == location_id }
         # FIXME traverse all of loc's descendants, and if remote location
         # server is specified, send request to get child location, swapping
         # it in for the one thats there
       rescue Exception => e
         Logger.warn "get location #{location_id} failed w/ exception #{e}"
       end
       Logger.info "get location #{location_id} request returning #{loc}"
       loc
    }

    rjr_dispatcher.add_handler('create_location') { |location|
       Logger.info "received create location request"
       location = Location.new if location.nil?
       ret = location
       begin
         location.x = 0 if location.x.nil?
         location.y = 0 if location.y.nil?
         location.z = 0 if location.z.nil?

         # TODO decendants support w/ remote option (create additional locations on other servers)
         Runner.instance.run location

       rescue Exception => e
         Logger.warn "create location failed w/ exception #{e}"
         ret = nil
       end
       Logger.info "create location request created and returning #{ret.id}"
       ret
    }

    rjr_dispatcher.add_handler("update_location") { |location|
       Logger.info "received update location #{location.id} request"
       success = true
       if location.nil?
         success = false
       else
         rloc = Runner.instance.locations.find { |loc| loc.id == location.id  }
         begin
           # store the old location coordinates for comparison after the movement
           old_coords = [location.x, location.y, location.z]

           # FIXME XXX big problem/bug here, client must always specify location.movement_strategy, else location constructor will set it to stopped
           # FIXME this should halt location movement, update location, then start it again
           Logger.info "updating location #{location.id} with #{location}/#{location.movement_strategy}"
           rloc.update(location)

           # FIXME trigger location movement & proximity callbacks (make sure to keep these in sync w/ those invoked the the runner)
           # right now we can't do this because a single simrpc node can't handle multiple sent message response, see FIXME XXX in lib/simrpc/node.rb
           #rloc.movement_callbacks.each { |callback|
           #  callback.invoke(rloc, *old_coords)
           #}
           #rloc.proximity_callbacks.each { |callback|
           #  callback.invoke(rloc)
           #}

         rescue Exception => e
           Logger.warn "update location #{location.id} failed w/ exception #{e}"
           success = false
         end
       end
       Logger.info "update location #{location.id} returning #{success}"
       success
    }
  end
end

end # module Motel
