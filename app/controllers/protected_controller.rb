class ProtectedController < ApplicationController
  #before_filter :set_current_user
  before_filter :login_required, :except => [ :category, :login, :signup, :create_profile, :password_recovery, :login_as, :feed, :create_en_masse ]
  
  #def set_current_user
  #  User.current = session[:user]
  #end
  
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
    @category = find_in_users_categories(params[:id])
    raise ActiveRecord::RecordNotFound unless @category
    @groups   = @category.groups & current_user.groups
    
    @assets = accessible_items(@category, 'assets', @groups)
    @articles = accessible_items(@category, 'articles', @groups)
  end 

  def accessible_items(category,items,groups)
    good_items = []
    all_items = category.send(items)
    all_items.each do |i|
      good_items << i unless(i.groups & groups).empty?
    end
    good_items
  end
   
end
