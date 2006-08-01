module AdminController::CategoryMethods
  def list_categories
    @category_pages, @categories = paginate :categories, :per_page => 10
    render 'admin/list_categories'
  end
end