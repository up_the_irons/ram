#!/usr/bin/ruby -w

require 'yaml'

# Two ways of going about this

if false

require 'soap/rpc/driver'

proxy = SOAP::RPC::Driver.new("http://localhost:3030/services/api", nil, '/services/assets/')
proxy.add_method('Get', 'username', 'password', 'ids') # Must be 'Get', not 'get'
puts proxy.Get('admin','admin', [1]).to_yaml

else

require 'soap/wsdlDriver'

ws = SOAP::WSDLDriverFactory.new('http://localhost:3030/services/service.wsdl').create_rpc_driver
ws.wiredump_dev = STDOUT
puts ws.methods.sort
puts ws.get('admin','admin',[1]).to_yaml

end
