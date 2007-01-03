#!/usr/bin/ruby -w

require 'xmlrpc/client'

server = XMLRPC::Client.new2("http://localhost:3030/services/api")

# Using proxy
ws = server.proxy('assets')
puts ws.get('admin', 'admin', [1])
