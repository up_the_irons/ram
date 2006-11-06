class SearchController < ProtectedController
  include Sortable

  sortable :all, :assets, :categories, :groups
  paging   :assets, :categories, :groups

  def all
    assets
    categories
    groups
    articles
    # Reset these module params (note: the modules should take care of this automatically at some point)
    params[:sort] = params[:sort_dir] = params[:page] = nil

    flash[:notice] = "Your search returned no results." if @assets.empty? and @articles.empty? and @cats.empty? and @groups.empty? and @cats.empty?
  rescue
    redirect_to :controller => 'inbox'
    flash[:notice] = "You need to belong to at least one group for search to work."
  end

  def assets
    @assets = current_user.assets_search(params[:id], @order)
    @assets_pages, @assets = paginate_collection(@assets, :per_page => params[:num_per_page], :page => params[:page])
    @sort_header_url    = { :action => 'assets' }
    @paging_url_options = { :action => 'assets' } 

    conditional_render
  end
  
  
  def articles
    @articles = current_user.articles_search(params[:id], @order)
    conditional_render
  end

  def categories
    @cats   = current_user.categories_search(params[:id], @order)

    # TODO: Implement pagination for categories in search results
    # @cats_pages, @cats = paginate_collection(@cats, :per_page => params[:num_per_page], :page => params[:page])
    
    conditional_render
  end

  def groups
    @groups = current_user.groups_search(params[:id], @order)

    # TODO: Implement pagination for groups in search results
    # @groups_pages, @groups = paginate_collection(@groups, :per_page => params[:num_per_page], :page => params[:page])
    
    conditional_render
  end

  protected

  def conditional_render
    case action_name
    when 'assets'
      render :update do |page|
        page.replace_html :asset_list, :partial => 'asset/list'
      end
    when /(categories|groups|articles)/
      render :update do |page|
        page.replace_html(($1.singularize + "_list"), :partial => "#{$1.singularize}/details")
      end
    end
  end

end
