#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class ProtectedController < ApplicationController
  before_filter :login_required, :except => [ :category, :login, :signup, :create_profile, :forgot_password, :login_as, :create_en_masse, :google]
  
  # Helper methods for scope relative searches
  def find_in_users_groups(id)
    g = Group.find(id)
    return g if current_user.groups.include? g
  end
  
  def find_in_users_categories id
    c = Category.find(id)
    return c if current_user.categories.include? c
  end
  
  def create_avatar(user_id, data)
    avatar = Avatar.find_by_user_id(user_id)
    if avatar
      avatar.uploaded_data = data
      avatar.save
    else
      avatar = Avatar.create({ :user_id => user_id, :uploaded_data => data })
    end
    avatar
  end
  
  protected

  def category_contents(params, order = nil)
    @category = find_in_users_categories(params[:id])
    raise ActiveRecord::RecordNotFound unless @category
    @groups   = @category.groups & current_user.groups

    @assets = accessible_items(@category, 'assets', @groups, order)
    @asset_pages, @assets = paginate_collection(@assets, :per_page => params[:num_per_page], :page => params[:page])

    @articles = accessible_items(@category, 'articles', @groups)
    @article_pages, @articles = paginate_collection(@articles, :per_page => params[:num_per_page], :page => params[:page])
  end 

  def accessible_items(category, items, groups, order = nil)
    good_items = []
    all_items = category.send(items).find(:all, :order => order)
    all_items.each do |i|
      good_items << i unless(i.groups & groups).empty?
    end
    good_items
  end
   
end
