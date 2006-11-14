#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class ChangeObserver < ActiveRecord::Observer
  observe Group, User, Category, Asset, Article
  
  def after_destroy(record)
    log(record, "DESTROY")
    log_for_child(record, "Removed #{record.name}")
  end

  def after_update(record)
    log(record, "UPDATE")
  end

  def after_create(record)
    log(record, "CREATE")
    log_for_child(record, "Added #{record.name}")    
  end
  
  protected
  
  def log_for_child(record, event, user = nil)
    case record.class.to_s
      when 'Asset', 'Article':
        return if record.category_id.nil?
        category = Category.find(record.category_id)  
        log( category, event) unless record.category_id.nil?
      
      when 'Category':
        return if record.parent_id.nil?
        category = Category.find(record.parent_id)  
        log(category, event) unless record.parent_id.nil?
    end
  end
  
  def log(record, event, user = nil)
    user = controller.session[:user] unless controller.nil?
    Change.create(:record_id => record.id, :record_type => record.class.to_s, :event => event, :user_id => user)
  end
end
