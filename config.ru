#!/usr/bin/env rackup

require './lib/riak_cs_broker/app'
run RiakCsBroker::App.new
