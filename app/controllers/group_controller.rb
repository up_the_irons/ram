#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class GroupController < ProtectedController
  include EnlightenObservers

  observer :change_observer

  def index
    list
  end

  def list
    @group_pages, @groups = paginate_collection(current_user.groups, :page => @params[:page])
    render :partial => 'group/list', :layout => 'application'
  end

  def show
   @group = find_in_users_groups(params[:id])
   raise if @group.nil?

   rescue 
     redirect_to :controller => 'inbox'
     flash[:notice] = 'This group could not be found in your access list'
  end
end
