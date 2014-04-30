#!/usr/bin/ruby
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega'
require 'omega/client/dsl'
require 'omega/client/entities/ship'

include Omega::Client::DSL

$universe1 = 'jsonrpc://localhost:8889'
$universe2 = 'jsonrpc://localhost:8890'

RJR::Logger.log_level = ::Logger::DEBUG

node = RJR::Nodes::TCP.new :node_id    => 'runner'
dsl.rjr_node = node

$athena = $agathon = nil
$gate_to_athena = $gate_to_agathon = nil

#############################

dsl.node.endpoint = $universe1
login 'admin', 'nimda'

galaxy 'Zeus' do |g|
  $athena = system 'Athena', 'HR1925',
                   :id => 'Athena'
end

logout

#############################

dsl.node.endpoint = $universe2
login 'admin', 'nimda'

galaxy 'Hera' do |g|
  $agathon = system 'Agathon', 'JJ7192',
                    :id => 'Agathon'
end

proxied_system $athena.id, 'universe1',
               :name     => $athena.name,
               :location => $athena.location

$gate_to_athena = jump_gate $agathon, $athena

logout

#############################

dsl.node.endpoint = $universe1
login 'admin', 'nimda'

proxied_system $agathon.id, 'universe2',
               :name     => $agathon.name,
               :location => $agathon.location

$gate_to_agathon = jump_gate $athena, $agathon

user 'player', 'reylap' do |u|
  role :regular_user
end

ship("player-corvette-ship1") do |ship|
  ship.type     = :corvette
  ship.user_id  = 'player'
  ship.solar_system = system('Athena')
end

#############################

# XXX need to create player representation on remote server (for now)
dsl.node.endpoint = $universe2
login 'admin', 'nimda'
user 'player', 'reylap' do |u|
  role :regular_user
end

#############################

def log_player_into(server)
  logout
  Omega::Client::Trackable.node.endpoint = server
  dsl.node.endpoint = server
  login 'player', 'reylap'
end

def refresh_ship
  @sh ||= Omega::Client::Ship.get('player-corvette-ship1')
  @sh.refresh
  run_ship @sh
end

def run_ship(sh)
  if sh.system_id == 'Athena'
    sh.move_to(:location => $gate_to_agathon.location + [10, 10, 10]) do
      sh.jump_to('Agathon')
      log_player_into($universe2)
      refresh_ship
    end

  else
    sh.move_to(:location => $gate_to_athena.location + [10, 10, 10]) do
      sh.jump_to('Athena')
      log_player_into($universe1)
      refresh_ship
    end
  end
end

Omega::Client::Trackable.node.rjr_node = node
log_player_into($universe1)
refresh_ship
node.join
