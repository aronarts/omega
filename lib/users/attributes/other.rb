# Users module other attributes
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Users

module Attributes

# Controls mission related attributes such as number of missions
# a user can accept at a time
class MissionAgentLevel < Users::AttributeClass
  id           :mission_agent_level
  description  "Mission resolution competency"
end

# TODO also attribute for type of missions which can be accepted?

# many other various attributes can go here
# and things like from science / tech / research / politics / etc
# tracks can be incorporated as well

end

end
