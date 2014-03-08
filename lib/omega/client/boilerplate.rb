# Omega client boilerplate
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'

require 'omega'
require 'omega/client/dsl'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

# TODO env/other var specifying which transport used?
require 'rjr/nodes/tcp'
dsl.rjr_node = RJR::Nodes::TCP.new(:node_id =>    'seeder',
                                   :broker  => 'localhost',
                                   :port    =>      '9090')
#dsl.rjr_node.endpoint = 'jsonrpc://localhost:8181'