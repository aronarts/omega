# Users module ownership attributes
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

module Attributes

# Permits a user to own a specified number of entities
class NumberOfEntities < Users::AttributeClass
  id           :number_of_entities
  description  "Maximum number of manufactured entities a user may own"
end

# Permits a user to own a entities of a specified type
class EntityClass < Users::AttributeClass
end

end
end