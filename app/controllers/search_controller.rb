class SearchController < ProtectedController
  include Sortable

  sortable :all, :assets, :categories, :groups

  def all
    assets
    categories
    groups

   flash[:notice] = "Your search returned no results." if @assets.empty? and @cats.empty? and @groups.empty? and @cats.empty?
  rescue
    redirect_to :controller=>'inbox'
    flash[:notice] = "You need to belong to at least one group for search to work."
  end

  def assets
    @assets = current_user.assets_search(params[:id], @order)
    @sort_header_url = { :action => 'assets' }
    conditional_render
  end

  def categories
    @cats   = current_user.categories_search(params[:id], @order)
    conditional_render
  end

  def groups
    @groups = current_user.groups_search(params[:id], @order)
    conditional_render
  end

  protected

  def conditional_render
    case action_name
    when 'assets'
      render :update do |page|
        page.replace_html :asset_list, :partial => 'asset/list'
      end
    when /(categories|groups)/
      render :update do |page|
        page.replace_html(($1.singularize + "_list"), :partial => "#{$1.singularize}/details")
      end
    end
  end

end
