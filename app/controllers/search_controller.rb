class SearchController < ProtectedController
  def all
    @assets = current_user.assets_search(params[:id])
    @cats   = current_user.categories_search(params[:id])
    @groups = current_user.groups_search(params[:id])
    @cats   = current_user.categories_search(params[:id])
  rescue
    redirect_to :controller=>'inbox'
    flash[:notice] = "You need to belong to at least one group for search to work."
  end
end
