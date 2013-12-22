# omega roles data
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/user'

module Omega

# The Roles module provides mechanisms to assign privileges to users
# depending on roles assigned to them. A role is a named list of privileges
# some of which may be applied to entities or entity types.
module Roles

PRIVILEGE_VIEW     = 'view'
PRIVILEGE_CREATE  = 'create'
PRIVILEGE_MODIFY  = 'modify'
PRIVILEGE_DELETE = 'delete'

PRIVILEGES        = [PRIVILEGE_VIEW, PRIVILEGE_CREATE, PRIVILEGE_MODIFY, PRIVILEGE_DELETE]

ENTITIES_LOCATIONS    = 'locations'
ENTITIES_COSMOS       = 'cosmos_entities'
ENTITIES_MANUFACTURED = 'manufactured_entities'
ENTITIES_MANUFACTURED_RESOURCES = 'manufactured_resources'
ENTITIES_USERS        = 'users_entities'
ENTITIES_USER         = 'users'
ENTITIES_USER_ATTRIBUTES = 'user_attributes'
ENTITIES_USERS_EVENTS = 'users_events'
ENTITIES_PRIVILEGES   = 'privileges'
ENTITIES_ROLES        = 'roles'
ENTITIES_MISSIONS     = 'missions'
ENTITIES_UNASSIGNED_MISSIONS = "unassigned_missions"
ENTITIES_MISSION_EVENTS = 'mission_events'
ENTITIES_MISSIONS_HOOKS = 'missions_hooks'
ENTITIES_STATS       = 'stats'

ENTITY_LOCATION     = "location-"
ENTITY_COSMOS       = "cosmos_entity-"
ENTITY_MANUFACTURED = "manufacture_entity-"
ENTITY_USERS        = "users_entity-"
ENTITY_USER         = "user-"
ENTITY_MISSION      = "mission-"
ENTITY_USER_ATTRIBUTE = 'user_attribute'
ENTITY_ROLE         = 'role'

ENTITIES            = [ENTITIES_LOCATIONS, ENTITIES_COSMOS, ENTITIES_MANUFACTURED, ENTITIES_MANUFACTURED_RESOURCES,
                       ENTITIES_USERS, ENTITIES_USER, ENTITIES_USER_ATTRIBUTES, ENTITIES_USERS_EVENTS, ENTITIES_PRIVILEGES, ENTITIES_ROLES,
                       ENTITIES_MISSIONS, ENTITIES_UNASSIGNED_MISSIONS, ENTITIES_MISSION_EVENTS, ENTITIES_MISSIONS_HOOKS, ENTITIES_STATS]

ENTITYS             = [ENTITY_LOCATION,    ENTITY_COSMOS,   ENTITY_MANUFACTURED,
                       ENTITY_USERS,   ENTITY_USER,   ENTITY_MISSION,  ENTITY_USER_ATTRIBUTE, ENTITY_ROLE]

# Master dictionary of role names to lists of privileges and entities that they correspond to
ROLES = { :superadmin => PRIVILEGES.product(ENTITIES),
          :regular_user            => [[PRIVILEGE_VIEW, ENTITIES_COSMOS],    [PRIVILEGE_VIEW, ENTITIES_UNASSIGNED_MISSIONS], [PRIVILEGE_VIEW, ENTITIES_STATS], [PRIVILEGE_VIEW,   ENTITIES_MANUFACTURED], [PRIVILEGE_VIEW, ENTITIES_LOCATIONS]], # TODO doesn't take fog of war into account
          :anonymous_user          => [[PRIVILEGE_VIEW, ENTITIES_COSMOS],    [PRIVILEGE_VIEW, ENTITIES_UNASSIGNED_MISSIONS], [PRIVILEGE_VIEW, ENTITIES_STATS], [PRIVILEGE_VIEW,   ENTITIES_MANUFACTURED], [PRIVILEGE_VIEW, ENTITIES_LOCATIONS]]} # TODO pretty lax anonymous user


end # module Roles
end # module Omega
