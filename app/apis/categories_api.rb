class CategoriesApi < ActionWebService::API::Base #:nodoc:
  api_method :get, 
             :expects => [{ :username => :string },
                          { :password => :string },
                          { :ids      => [:int]  }],
             :returns => [[WebServiceStructs::CategoryStruct]]
end
