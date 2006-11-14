#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class CategoryObserver < ActiveRecord::Observer
  def after_save(record)
    return if controller.nil?

    controller.instance_eval do
      session[:category_tree] = current_user.categories_as_tree(true)
    end
  end

  alias :after_destroy :after_save
end
