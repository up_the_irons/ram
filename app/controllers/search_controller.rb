class SearchController < ProtectedController
  def all
    @assets = Asset.search(params[:query], current_user.groups.map { |o| o.id })
  end
end
