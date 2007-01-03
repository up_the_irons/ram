#!/usr/bin/ruby -w

require 'xmlrpc/client'

server = XMLRPC::Client.new2("http://localhost:3030/services/api")

# Using proxy
ws = server.proxy('assets')
file = ws.get('admin', 'admin', [1])[0]

File.open(file['filename'], "w") do |f|
  f.write(file['content'])
end
