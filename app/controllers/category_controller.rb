class CategoryController < ProtectedController
  cache_sweeper :change_sweeper
  layout "application", :except => [:feed]

  sortable :show

  def index
    list
  end
  
  def show
    if request.xhr?
      show_collection('categories') do
        category_contents(params, @order) 
        render :update do |page|
          page.replace_html :asset_list, :partial => 'asset/list'
        end
      end
    else
      #nest this in a boolean because show_collecction will return false if a resuce occurred
      # @order comes from the "sortable :show" directive above, automagically
      category_contents(params, @order) if show_collection('categories')
    end
     
    @sort_header_url = {}
  end
  
  def list
    list_collection do
      render :partial=>'category/list', :layout=>'application'
    end    
  end
  
end
