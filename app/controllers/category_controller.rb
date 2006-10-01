class CategoryController < ProtectedController
  cache_sweeper :change_sweeper
  layout "application", :except => [:feed]

  def index
    list
  end
  
  def show
    #nest this in a boolean because show_collecction will return false if a resuce occurred
    if show_collection('categories')
      category_contents(params)
    end
  end
  
  def list
    list_collection do
      render :partial=>'category/list', :layout=>'application'
    end    
  end
  
end
