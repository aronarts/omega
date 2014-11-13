# manufactured::transfer_resource rjr definitions
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/init'

module Manufactured::RJR

# transfer resource between entities
transfer_resource = proc { |*args|
  # retrieve src/dst ids and optional resources from args
  src_id    = args[0]
  dst_id    = args[1]
  resources = args[2..-1] if args.size > 2

  # retrieve/validate src / dst entities
  src = registry.entity &with_id(src_id)
  dst = registry.entity &with_id(dst_id)
  raise DataNotFound, src_id if src_id.nil? || ![Ship,Station].include?(src.class)
  raise DataNotFound, dst_id if dst.nil?    || ![Ship,Station].include?(dst.class)

  # require modify on entities
  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "manufactured_entity-#{src.id}"},
     {:privilege => 'modify', :entity => 'manufactured_entities'}]

  require_privilege :registry => user_registry, :any =>
    [{:privilege => 'modify', :entity => "manufactured_entity-#{dst.id}"},
     {:privilege => 'modify', :entity => 'manufactured_entities'}]

  # update src/dst locations from motel
  src.location = node.invoke('motel::get_location', 'with_id', src.location.id)
  dst.location = node.invoke('motel::get_location', 'with_id', dst.location.id)

  # if resources not specified, transfer all from source to dst
  resources = src.resources if resources.nil?

  # ensure src has resources
  resources.each { |r|
    raise ArgumentError,r unless r.valid? &&
                                 src.resources.find { |rs| rs.material_id ==
                                                           r.material_id }
  }

  # ensure transfer can take place
  raise OperationError,
      "cannot transfer" unless resources.all? { |r| src.can_transfer?(dst, r) }
  raise OperationError,
        "cannot accept" unless resources.all? { |r| dst.can_accept?(r) }

  # transfer resources via the registry
  registry.safe_exec { |entities|
    # retrieve registry src/dst
    s = entities.find &with_id(src.id)
    d = entities.find &with_id(dst.id)

    # iterate over resources
    resources.each { |r|
      added = removed = false
      begin
        # transfer resource
        d.add_resource(r)    ; added   = true
        s.remove_resource(r) ; removed = true

        # run transferred callbacks
        s.run_callbacks 'transferred_to',   d, r
        d.run_callbacks 'transferred_from', s, r
      rescue Exception => e
      ensure
        # if resources was added to dst but not
        # removed from src, remove it from dst
        d.remove_resource(r) if added && !removed
      end
    }

    src,dst = s,d
  }

  # return src, dst
  [src, dst]
}

TRANSFER_METHODS = { :transfer_resource => transfer_resource }

end # module Manufactured::RJR

def dispatch_manufactured_rjr_transfer(dispatcher)
  m = Manufactured::RJR::TRANSFER_METHODS
  dispatcher.handle 'manufactured::transfer_resource', &m[:transfer_resource]
end
