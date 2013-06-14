#!/usr/bin/ruby
# Medium sized universe
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO replace random axis + rand locations

require 'rubygems'
require 'omega'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

node = RJR::AMQPNode.new(:node_id => 'seeder', :broker => 'localhost')
login node, 'admin',  'nimda'

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925', :location => Location.new(:x => 240, :y => -360, :z => 110) do |sys|
    planet 'Posseidon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.013,
                                                :eccentricity => 0.6, :semi_latus_rectum => 1000,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Posseidon I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Posseidon II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Posseidon III', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Posseidon IV',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hermes',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.064,
                                                :eccentricity => 0.3, :semi_latus_rectum => 1834,
                                                :direction => Motel.random_axis)

    planet 'Apollo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.021,
                                                :eccentricity => 0.8, :semi_latus_rectum => 1929,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Apollo V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Apollo VII', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hades',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.064,
                                                :eccentricity => 0.9, :semi_latus_rectum => 1440,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hades III',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades V',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades VI',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades VII',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades VIII', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades IX',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XI',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XII',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XIII', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XIV',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 1000, :min_y => 0) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Aphrodite', 'V866', :location => Location.new(:x => -420, :y => 119, :z => 90) do |sys|
    planet 'Xenon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.011,
                                                :eccentricity => 0.8, :semi_latus_rectum => 1493,
                                                :direction => Motel.random_axis)
    planet 'Aesop',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.034,
                                                :eccentricity => 0.55, :semi_latus_rectum => 1296,
                                                :direction => Motel.random_axis)
    planet 'Cleopatra',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.022,
                                                :eccentricity => 0.42, :semi_latus_rectum => 1473,
                                                :direction => Motel.random_axis)
    planet 'Demon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.006,
                                                :eccentricity => 0.16, :semi_latus_rectum => 1070,
                                                :direction => Motel.random_axis)
    planet 'Lynos',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.065,
                                                :eccentricity => 0.3125, :semi_latus_rectum => 1373,
                                                :direction => Motel.random_axis)
    planet 'Heracules',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.051,
                                                :eccentricity => 0.49, :semi_latus_rectum => 1305,
                                                :direction => Motel.random_axis)
    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 1000, :min_y => 0) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Theodosia', 'ST9098', :location => Location.new(:x => 412, :y => -132, :z => 342) do |sys|
    planet 'Eukleides',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.036,
                                                :eccentricity => 0.21, :semi_latus_rectum => 1437,
                                                :direction => Motel.random_axis)

    planet 'Phoibe',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.03,
                                                :eccentricity => 0.1, :semi_latus_rectum => 1529,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Phiobe V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Phiobe VI',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Basilius',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.067,
                                                :eccentricity => 0.45, :semi_latus_rectum => 1864,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Basilius V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius VI',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XII', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XIII',:location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XV',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XX',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XXI', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Leonidas',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.067,
                                                :eccentricity => 0.55, :semi_latus_rectum => 1689,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Leonidas V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Pythagoras',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.004,
                                                :eccentricity => 0.66, :semi_latus_rectum => 1071,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Pythagoras V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Pythagoras VI',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Zeno',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.006,
                                                :eccentricity => 0.15, :semi_latus_rectum => 1684,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Zeno I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Zeno II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Zeno III', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Galene',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.022,
                                                :eccentricity => 0.62, :semi_latus_rectum => 1266,
                                                :direction => Motel.random_axis)
  end

  system 'Nike', 'QR1515', :location => Location.new(:x => -222, :y => 333, :z => 413) do |sys|
    planet 'Nike I',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.039,
                                                :eccentricity => 0.12, :semi_latus_rectum => 1510,
                                                :direction => Motel.random_axis)
    planet 'Nike II',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.004,
                                                :eccentricity => 0.94, :semi_latus_rectum => 1436,
                                                :direction => Motel.random_axis)
    planet 'Nike III',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.009,
                                                :eccentricity => 0.42, :semi_latus_rectum => 1290,
                                                :direction => Motel.random_axis)
    planet 'Nike IV',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.033,
                                                :eccentricity => 0.13, :semi_latus_rectum => 1088,
                                                :direction => Motel.random_axis)
    planet 'Nike V',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.009,
                                                :eccentricity => 0.291, :semi_latus_rectum => 1712,
                                                :direction => Motel.random_axis)
    planet 'Nike VI',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.031,
                                                :eccentricity => 0.388, :semi_latus_rectum => 1174,
                                                :direction => Motel.random_axis)
    planet 'Nike VII',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.011,
                                                :eccentricity => 0.77, :semi_latus_rectum => 1100,
                                                :direction => Motel.random_axis)
    planet 'Nike VIII',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.009,
                                                :eccentricity => 0.22, :semi_latus_rectum => 1500,
                                                :direction => Motel.random_axis)
    planet 'Nike IX',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.015,
                                                :eccentricity => 0.32, :semi_latus_rectum => 1508,
                                                :direction => Motel.random_axis)
    planet 'Nike X',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.046,
                                                :eccentricity => 0.64, :semi_latus_rectum => 1160,
                                                :direction => Motel.random_axis)
  end

  system 'Philo', 'HU1792', :location => Location.new(:x => -142, :y => -338, :z => 409) do |sys|
    planet 'Theophila',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.057,
                                                :eccentricity => 0.88, :semi_latus_rectum => 1662,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Theophila X',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Theophila XI',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Theophila XII',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Zosime',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.06,
                                                :eccentricity => 0.25, :semi_latus_rectum => 1203,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Zosime I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Xeno',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.055,
                                                :eccentricity => 0.16, :semi_latus_rectum => 1814,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Xeno I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Xeno II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 1000, :min_y => 0) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }

  end

  system 'Aphroditus', 'V867', :location => Location.new(:x => -420, :y => 119, :z => 90) do |sys|
    planet 'Xenux',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.025,
                                                :eccentricity => 0.8, :semi_latus_rectum => 1441,
                                                :direction => Motel.random_axis)
    planet 'Aesou',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.009,
                                                :e => 0.7, :p => 124, :direction => Motel.random_axis)
  end

  system 'Irene', 'HZ1279', :location => Location.new(:x => 110, :y => 423, :z => -455) do |sys|
    planet 'Irene I',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.037,
                                                :eccentricity => 0.29, :semi_latus_rectum => 1280,
                                                :direction => Motel.random_axis)
    planet 'Irene II',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.04,
                                                :eccentricity => 0.40, :semi_latus_rectum => 1038,
                                                :direction => Motel.random_axis)
    planet 'Korinna',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.033,
                                                :eccentricity => 0.71, :semi_latus_rectum => 1502,
                                                :direction => Motel.random_axis)
    planet 'Gaiane',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.013,
                                                :eccentricity => 0.68, :semi_latus_rectum => 1367,
                                                :direction => Motel.random_axis)
    planet 'Demetrius',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.053,
                                                :eccentricity => 0.223, :semi_latus_rectum => 1078,
                                                :direction => Motel.random_axis)
  end
end

jump_gate system('Athena'), system('Aphrodite'), :location => Location.new(:x => -150, :y => -150, :z => -150)
jump_gate system('Athena'), system('Philo'), :location => Location.new(:x => 150, :y => 150, :z => 150)
jump_gate system('Aphrodite'), system('Athena'), :location => Location.new(:x => -150, :y => 150, :z => -150)
jump_gate system('Aphrodite'), system('Philo'), :location => Location.new(:x => 150, :y => -150, :z => 150)
jump_gate system('Philo'), system('Aphrodite'), :location => Location.new(:x => 150, :y => -150, :z => 150)

galaxy 'Hera' do |g|
  system 'Agathon', 'JJ7192', :location => Location.new(:x => -88, :y => 219, :z => 499) do |sys|
    planet 'Tychon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.022,
                                                :eccentricity => 0.33, :semi_latus_rectum => 1815,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Tyhon I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Tyhon II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Pegasus',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.06,
                                                :eccentricity => 0.42, :semi_latus_rectum => 1458,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Pegas',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Olympos',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.043,
                                                :eccentricity => 0.52, :semi_latus_rectum => 1413,
                                                :direction => Motel.random_axis)

    planet 'Zotikos',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.031,
                                                :eccentricity => 0.31, :semi_latus_rectum => 1037,
                                                :direction => Motel.random_axis)

    planet 'Zopyros',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.004,
                                                :eccentricity => 0.66, :semi_latus_rectum => 1968,
                                                :direction => Motel.random_axis)

    planet 'Kallisto',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.062,
                                                :eccentricity => 0.46, :semi_latus_rectum => 1519,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Myrrine',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Eugenia',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Doris',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Draco',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dion',      :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Elpis',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 1000, :min_y => 0) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Isocrates', 'IL9091', :location => Location.new(:x => -104, :y => -399, :z => -438) do |sys|
    planet 'Isocrates I',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.063,
                                                :eccentricity => 0.42, :semi_latus_rectum => 1380,
                                                :direction => Motel.random_axis)

    planet 'Isocrates II',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.051,
                                                :eccentricity => 0.42, :semi_latus_rectum => 1338,
                                                :direction => Motel.random_axis)

    planet 'Isocrates III',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.033,
                                                :eccentricity => 0.42, :semi_latus_rectum => 1163,
                                                :direction => Motel.random_axis)
  end

  system 'Thais', 'QR1021', :location => Location.new(:x => 116, :y => 588, :z => -91) do |sys|
    planet 'Rhode',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.026,
                                                :eccentricity => 0.5, :semi_latus_rectum => 1352,
                                                :direction => Motel.random_axis)
  end

  system 'Timon', 'FZ6675', :location => Location.new(:x => 88, :y => 268, :z => 91)
  system 'Zoe',   'FR7751', :location => Location.new(:x => -81, :y => -178, :z => -381)
  system 'Myron', 'RZ9901', :location => Location.new(:x => 498, :y => -114, :z => 101)

  system 'Lysander', 'V21', :location => Location.new(:x => 231, :y => 112, :z => 575) do |sys|
    planet 'Lysandra',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.065,
                                                :eccentricity => 0.46, :semi_latus_rectum => 1944,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Lysandra I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Lysandra II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Lysandrus',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.032,
                                                :eccentricity => 0.49, :semi_latus_rectum => 1048,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Lysandrus I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Lysandrene',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.021,
                                                :eccentricity => 0.66, :semi_latus_rectum => 1422,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Lysandrene I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Pelagia', 'HR1001', :location => Location.new(:x => -212, :y => -321, :z => 466) do |sys|
    planet 'Iason',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.05,
                                                :eccentricity => 0.48, :semi_latus_rectum => 1962,
                                                :direction => Motel.random_axis)
    planet 'Dionysius',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.049,
                                                :eccentricity => 0.69, :semi_latus_rectum => 1125,
                                                :direction => Motel.random_axis)
  end

  system 'Pericles', 'ST5309', :location => Location.new(:x => -156, :y => -341, :z => -177)
  system 'Sophia',   'ST5310', :location => Location.new(:x => 266, :y => -255, :z => -244)
  system 'Theodora', 'ST5311', :location => Location.new(:x => 500, :y => 118, :z => 326)

  system 'Tycho', 'Q931', :location => Location.new(:x => 420, :y => -420, :z => 420) do |sys|
    planet 'Agape',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.05,
                                                :eccentricity => 0.16, :semi_latus_rectum => 1904,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Agape I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Agape II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Argyros',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.035,
                                                :eccentricity => 0.16, :semi_latus_rectum => 1723,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Argyrosa I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Argyrosus',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.06,
                                                :eccentricity => 0.55, :semi_latus_rectum => 1522,
                                                :direction => Motel.random_axis)

    planet 'Hero',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.039,
                                                :eccentricity => 0.33, :semi_latus_rectum => 1723,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hero I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hero II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hero III', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hero IV',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Stephanos', 'ST111', :location => Location.new(:x => 51, :y => -63, :z => 500)
end