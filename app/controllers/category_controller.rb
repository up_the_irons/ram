class CategoryController < ProtectedController
  layout "application", :except => [:feed]
  def initialize
    #CollectionMethods.create_show_method_for('categories') 
    #CollectionMethods.create_list_method_for('categories')
  end

  def index
    list
  end
  
  def show
    show_collection('categories')
  end
  
  def list
    list_collection do
      render :partial=>'category/list', :layout=>'application'
    end    
  end
  
  def feed
    category_contents(params)
  end
  
end
