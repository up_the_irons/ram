class CategoryController < ProtectedController
  cache_sweeper :change_sweeper
  layout "application", :except => [:feed]

  def index
    list
  end
  
  def show
    #nest this in a boolean because show_collecction will return false if a resuce occurred
    category_contents(params) if show_collection('categories')
  end
  
  def list
    list_collection do
      render :partial=>'category/list', :layout=>'application'
    end    
  end
  
end
