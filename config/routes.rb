ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "account", :action=>"login"
  
  ['groups','users','categories'].each do |model|
    ['edit', 'show'].each do |action|

      # Create a catch for singular models as well (e.g. user/edit/)
      map.connect "admin/#{action}/#{model.singularize}/:id",:controller=>'admin',:action=>"#{action}_#{model.singularize}"

      # Create a catch for plural models (e.g. users/edit)
      map.connect "admin/#{action}/#{model}/:id",:controller=>'admin',:action=>"#{action}_#{model.singularize}"
      map.connect "admin/#{model}",:controller=>'admin',:action=>"#{model}"
    end
  end
  
  # This is how you make a static route.
  # m.connect('404', 'public/404.html', _static=True )
  
  map.connect "admin/disband/group/:id", :controller=>'admin',:action=>'disband_group'
  
  map.connect "about", :controller=>'site',:action=>'about'
  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
