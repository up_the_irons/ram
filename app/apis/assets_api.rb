class AssetsApi < ActionWebService::API::Base #:nodoc:
  inflect_names false

  api_method :find, 
             :expects => [:text => :string]

  api_method :get, 
             :expects => [{ :username => :string },
                          { :password => :string },
                          { :ids      => [:int]  }],
             :returns => [[WebServiceStructs::AssetStruct]]

  api_method :update,
             :expects => [{ :username => :string     },
                          { :password => :string     },
                          { :id       => :int        },
                          { :asset    => WebServiceStructs::AssetStruct }]
end
