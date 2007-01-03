class TestApi < ActionWebService::API::Base #:nodoc:
  inflect_names false

  api_method :echo, 
             :expects => [:string],
             :returns => [:string]
  api_method :null, :expects => []
end


