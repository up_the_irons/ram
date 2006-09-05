class SearchController < ProtectedController
  def all
    @assets = current_user.assets_search(params[:query])
    @cats   = current_user.categories_search(params[:query])
    @groups = current_user.groups_search(params[:query])
  end
end
