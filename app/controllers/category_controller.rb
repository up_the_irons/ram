class CategoryController < ProtectedController
  cache_sweeper :change_sweeper

  sortable       :show
  paging_with_db :show

  def index
    list
  end
  
  def show
    if request.xhr?
      show_collection({:table=>'categories'}) do
        category_contents(params, @order) 
        params[:model] = "asset" if params[:model].nil?
        render :update do |page|
          page.replace_html "#{params[:model]}_list".to_sym, :partial => "#{params[:model]}/list"
        end
      end
    else
      #nest this in a boolean because show_collecction will return false if a resuce occurred
      # @order comes from the "sortable :show" directive above, automagically
      category_contents(params, @order) if show_collection({:table=>'categories'})
    end
     
    @sort_header_url = {}
  end
  
  def list
    list_collection do
      render :partial=>'category/list', :layout=>'application'
    end    
  end
  
end
