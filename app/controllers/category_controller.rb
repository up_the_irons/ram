#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
# 
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class CategoryController < ProtectedController
  include EnlightenObservers

  observer :change_observer

  sortable :show
  paging   :show, :index

  def index
    if current_user.categories.empty?
      flash[:notice] = "Your do not have access to any categories."
      render :text => "", :layout => 'application'
    else
      redirect_to :action=>"show", :id => current_user.categories_as_tree{:root}[:root][:children][0][:id]
    end
  end
  
  def show
    if request.xhr?
      show_collection({:table=>'categories'}) do
        category_contents(params, @order) 
        params[:model] = "asset" if params[:model].nil?
        render :update do |page|
          page.replace_html "#{params[:model]}_list".to_sym, :partial => "#{params[:model]}/list"
        end
      end
    else
      # Nest this in a boolean because show_collecction will return false if a resuce occurred
      # @order comes from the "sortable :show" directive above, automagically
      category_contents(params, @order) if show_collection({:table=>'categories'})
    end
     
    @sort_header_url = {}
  end  
end
