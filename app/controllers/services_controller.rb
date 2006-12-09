class ServicesController < ApplicationController
  wsdl_service_name 'Services'
  
  web_service_dispatching_mode :layered

  web_service_scaffold :invoke

  web_service :test,   TestService.new
  web_service :assets, AssetsService.new
end
