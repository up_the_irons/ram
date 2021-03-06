#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class Linking < ActiveRecord::Base
  belongs_to :user,     :foreign_key => 'user_id' 
  belongs_to :group,    :foreign_key => 'group_id',    :class_name => 'Group'
  belongs_to :category, :foreign_key => 'category_id', :class_name => 'Category'
  belongs_to :asset,    :foreign_key => 'linkable_id', :class_name => 'Asset'
  belongs_to :article,  :foreign_key => 'linkable_id', :class_name => 'Article'
  belongs_to :linkable, :polymorphic => true
  
  def join(opts)
    linking = { :user_id => nil, :category_id => nil, :group_id => nil, :linkable_id => nil, :linkable_type => nil }.merge(opts)
    if self.new_record?
      self.create(linking)
    else
      self.attributes.merge(opts)
      self.save!
    end
  end
  
  def break(linking)
  end
  
  def break_all(linking)
  end
  
  validates_uniqueness_of :linkable_id, :scope => [:group_id, :category_id, :linkable_type], :message => 'already added.'
end
