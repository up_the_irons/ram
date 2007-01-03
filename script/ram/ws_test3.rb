#!/usr/bin/ruby -w

require 'xmlrpc/client'
require 'yaml'

server = XMLRPC::Client.new2("http://localhost:3030/services/api")

# Using proxy
ws = server.proxy('assets')
puts ws.get('admin', 'admin', [1]).to_yaml

# Direct call
puts server.call("assets.get", 'admin', 'admin', [1]).to_yaml

# Category example
ws = server.proxy('categories')
puts ws.get('admin', 'admin', [2]).to_yaml
puts server.call("categories.get", 'admin', 'admin', [2]).to_yaml
