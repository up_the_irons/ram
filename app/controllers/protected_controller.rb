class ProtectedController < ApplicationController; end
require_dependency 'collection_methods'
class ProtectedController
  include CollectionMethods
  include AuthenticatedSystem


  before_filter :set_current_user
  before_filter :login_required, :except => [ :login, :signup, :create_profile, :password_recovery, :login_as, :feed, :create_en_masse ]
  
  def set_current_user
    User.current = session[:user]
  end
  
  #helper methods for scope relative searches
  def find_in_users_groups(id)
    g = Group.find(id)
    return g if current_user.groups.include? g
  end
  
  def find_in_users_categories id
    c = Category.find(id)
    return c if current_user.categories.include? c
  end
  
  protected
  def category_contents(params)
    params[:display] = 'all' if params[:display].nil?
    @category = find_in_users_categories(params[:id])
    @groups   = @category.groups & current_user.groups
    case params[:display]
      when 'assets'
        @assets = find_assets(@category,@groups)
      when 'articles'
        @articles = find_articles(@category)
      else
      #find all
      @assets   = find_assets(@category,@groups)
      @articles = find_articles(@category)
    end
  end 
  
  def find_assets(category,groups)
    good_assets = []
    assets = category.assets
    assets.each do |asset|
      good_assets << asset unless (asset.groups & groups).empty?
    end
    good_assets
  end
  
  def find_articles(category)
    category.articles  #TODO: This needs to be scoped to a group in the same way assets are.
  end
   
end
