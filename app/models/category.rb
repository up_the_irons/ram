#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class Category < Collection
  acts_as_tree 
  acts_as_taggable

  include TagMethods

  has_many :assets, :order => 'updated_on DESC'
  has_many :articles, :order => 'published_at DESC'
  has_many :memberships, :foreign_key => :collection_id
  has_many :linkings
 
  has_many :changes, :finder_sql=>'SELECT DISTINCT * ' +
        'FROM changes c WHERE c.record_id = #{id} AND c.record_type = "Category" ORDER BY c.created_at'

  has_many :children, :class_name => 'Collection', :foreign_key => 'parent_id' do
    def << (category)
      return if @owner.children.include?category
      @owner.children << category
    end
  end

  has_many :groups, :through => :linkings, :select => "DISTINCT collections.*", :foreign_key=>:group_id do
    def <<(group)
      return if @owner.groups.include?group

      # after_save() callback is triggered and entire event is atomic (put in a transaction)
      @owner.transaction do
        a = Linking.create(:group_id => group.id, :category_id => @owner.id)
        a.save!
        @owner.instance_eval { callback(:after_save) }
      end
    end  
  end
  
  def contents
    [articles,assets]
  end
  
  def remove_all_groups
    self.groups.each do |m| 
      remove_group(m)
    end
  end

  def remove_group(group)
    linking = Linking.find_by_category_id_and_group_id(self.id, group.id)
    linking.destroy if linking.valid?
    callback(:after_save)
  end
  
  class <<self
    def find_by_id_or_name(id)
      id.to_s.match(/^\d+$/) ? find(id) : find_by_name(id)
    end
  end

  validates_presence_of   :user_id, :name
  validates_uniqueness_of :name, :scope => :parent_id
  
  # TODO: After create automatically add this category to the administrators group.
  # TODO: After create automatically add this category to the user group list if none is supplied || allow users to see categories where they are the owner.. even if they don't belong to a group containing that category.
  def validate
    errors.add_to_base "The category cannot specify itself as the parent" if parent_id == id and !new_record?
    errors.add_to_base "The category must belong to at least one group" if groups.empty? and !new_record?
  end

end
