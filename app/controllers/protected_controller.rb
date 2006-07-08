class ProtectedController < ApplicationController
  include AuthenticatedSystem
  before_filter :set_current_user
  before_filter :login_required, :except => [ :login, :signup, :create_profile, :password_recovery, :login_as, :feed ]

  
  def set_current_user
    User.current = session[:user]
  end
  
  #helper methods for scope relative searches
  def find_in_users_groups id
    g = Group.find(id)
    #puts g.to_yaml
    return g if current_user.groups.include? g
  end
  
  def find_in_users_categories id
    # todo hopefully there will be away to improve this so that you will not need to load all of the user's categories into memory before you search for it.
    current_user.categories.each do |c|
      return Category.find(c.id) if c.id.to_i.eql? id.to_i
    end
    return nil
  end
  
end