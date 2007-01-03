class CategoriesApi < ActionWebService::API::Base #:nodoc:
  inflect_names false

  api_method :get, 
             :expects => [{ :username => :string },
                          { :password => :string },
                          { :ids      => [:int]  }],
             :returns => [[WebServiceStructs::CategoryStruct]]
end
