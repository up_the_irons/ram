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
    list
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
  
  def list
    list_collection do
      respond_to do |wants|
        wants.html do
          render :partial => 'category/list', :layout => 'application'
        end
        wants.js do 
          render :update do |page|
            page.replace_html 'category_list', :partial => 'category/list'
          end
        end
      end
    end    
  end
  
end
