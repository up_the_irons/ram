class TestApi < ActionWebService::API::Base #:nodoc:
  api_method :echo, 
             :expects => [:string],
             :returns => [:string]
  api_method :null, :expects => []
end


