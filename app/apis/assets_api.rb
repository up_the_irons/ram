class AssetsApi < ActionWebService::API::Base #:nodoc:
  api_method :get, 
             :expects => [{ :username => :string },
                          { :password => :string },
                          { :ids      => [:int]  }],
             :returns => [[AssetStruct]]

  api_method :update,
             :expects => [{ :username => :string     },
                          { :password => :string     },
                          { :id       => :int        },
                          { :asset    => AssetStruct }]

  api_method :search, 
             :expects => [:text => :string]
end
