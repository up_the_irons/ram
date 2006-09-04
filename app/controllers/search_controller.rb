class SearchController < ProtectedController
  def all
    @assets = Asset.search(params[:query], current_user.groups.map { |o| o.id })
    @cats   = current_user.categories_search(params[:query])
  end
end
