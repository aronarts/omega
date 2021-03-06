# The Rotatable MovementStrategy Mixin
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rjr/common'

module Motel
module MovementStrategies
  # Mixin to include in other modules to provide rotation
  # capabilities while undergoing other movement
  module Rotatable
    # Axis angle describing rotation
    attr_accessor :rot_x, :rot_y, :rot_z, :rot_theta

    # Stop location rotation automatically after this many degrees, optional
    attr_accessor :stop_angle

    # Rotation direction as an array
    def rot_dir
      [rot_x, rot_y, rot_z]
    end

    # Set rot dir
    def rot_dir=(*dir)
      dir = dir.flatten
      @rot_x = dir[0]
      @rot_y = dir[1]
      @rot_z = dir[2]
    end

    # Initialize rotation params from args hash
    def init_rotation(args = {})
      attr_from_args args, :rot_theta => 0,
                           :rot_x     => 0,
                           :rot_y     => 0,
                           :rot_z     => 1,
                           :stop_angle => nil
    end

    # Return boolean indicating if rotation parameters are valid
    def valid_rotation?
     @rot_theta.numeric? && @rot_theta > -6.28 && @rot_theta < 6.28 &&
     @rot_x.numeric? && @rot_y.numeric? && @rot_z.numeric? &&
     Motel.normalized?(@rot_x, @rot_y, @rot_z)
    end

    # Return boolean indicating if location has rotated by specified stop_angle
    def change_due_to_rotation?(loc)
      !stop_angle.nil? && loc.angle_rotated >= stop_angle
    end

    alias :rotation_stopped? :change_due_to_rotation?

    def rotating?(loc)
      rot_theta != 0 && (stop_angle.nil? || loc.angle_rotated < stop_angle)
    end

    def will_rotate_past_stop?(loc, angle)
      !stop_angle.nil? && (loc.angle_rotated + angle.abs) > stop_angle
    end

    # Rotate the specified location. Takes same parameters
    # as Motel::MovementStrategy#move to update location's
    # orientation after the specified elapsed interval.
    def rotate(loc, elapsed_seconds)
      # TODO rotational acceleration

      # new angle to rotate
      angle_rotated = @rot_theta * elapsed_seconds

      # stop at stop angle
      nangle        = angle_rotated < 0
      adjusted      = (stop_angle - loc.angle_rotated) * (nangle ? -1 : 1 ) if stop_angle
      angle_rotated = adjusted if will_rotate_past_stop?(loc, angle_rotated)

      # update location's orientation
      nor =
        Motel.rotate(loc.orx, loc.ory, loc.orz,
                     angle_rotated,
                     @rot_x, @rot_y, @rot_z)
      loc.orx = nor[0]
      loc.ory = nor[1]
      loc.orz = nor[2]
      loc.angle_rotated += angle_rotated.abs
      loc.orientation
    end

    # Return string representation of rotation
    def rot_to_s
      "#{rot_theta.round_to(2)}/#{rot_x.round_to(2)}/#{rot_y.round_to(2)}/#{rot_z.round_to(2)}"
    end

    # Return rotation params to incorporate in json value
    def rotation_json
      {:rot_theta => rot_theta,
       :rot_x     => rot_x,
       :rot_y     => rot_y,
       :rot_z     => rot_z,
       :stop_angle => stop_angle}
    end
  end # module Rotatable
end # module MovementStrategies
end # module Motel
