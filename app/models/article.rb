#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

# TODO: Remove the status row if it is not going to be used. 

class Article < ActiveRecord::Base
  acts_as_tree
  acts_as_taggable

  validates_presence_of :user_id, :body, :title, :message => 'cannot be blank'

  belongs_to :user
  belongs_to :category

  has_many :comments, :dependent => true, :order => "created_at ASC"
  has_many :linkings, :as => :linkable, :dependent => :destroy
  has_many :groups, :through => :linkings do
    def << (group)
      return if @owner.groups.include?(group)
      l = Linking.find_or_create_by_linkable_id_and_linkable_type_and_group_id(@owner.id, "Article", group.id)
      l.errors.each_full { |msg| puts msg } unless l.save
      @owner.groups(true) # Force the reload
    end
  end
  
  has_many :changes, :finder_sql => 'SELECT DISTINCT * ' +
        'FROM changes c WHERE c.record_id = #{id} AND c.record_type = "Article" ORDER BY c.created_at'
  
  # FIXME
  #attr_protected :user_id
  
  # Snipped from Mephisto (http://www.mephistoblog.com/)
  after_validation :convert_to_utc
  before_create    :create_permalink
  
  def comments
    children
  end
  
  def author
    user_id
  end
  
  def name
    title
  end
  
  def comment_count
    children_count
  end
  
  def tags=(str)
    arr = str.split(",").uniq
    self.tag_with arr.map { |a| a }.join(",")
  end
  
  # Snipped from Mephisto's post model (http://www.mephistoblog.com/)
  def published?
    !new_record? && !published_at.nil?
  end

  def pending?
    published? && Time.now.utc < published_at
  end

  def status
    pending? ? :pending : :published
  end
  
  def publish
    self.published_at = Time.now.utc
    save!
  end
  
  # Follow Mark Pilgrim's rules on creating a good ID
  # http://diveintomark.org/archives/2004/05/28/howto-atom-id
  def guid
    "/#{self.class.to_s.underscore}#{full_permalink}"
  end

  def full_permalink
    published? && ['', published_at.year, published_at.month, published_at.day, permalink] * '/'
  end
  
  def allow_comments?
    allow_comments
  end
  
  # TODO: Fefactor this so that the classes which are linked though groups can share the same module instead of duplicating code.
  def remove_all_groups
    self.groups.each do |m| 
      remove_group(m)
    end
  end
  
  def remove_group(group)
    linking = Linking.find_by_linkable_id_and_linkable_type_and_group_id(self.id, 'Article', group.id)
    linking.destroy if linking.valid?
  end

  class << self      
    def search(query, groups, order = nil)
      groups = [groups].flatten
      find(:all, :select => "articles.*", :joins => "INNER JOIN linkings ON articles.id = linkings.linkable_id", :conditions => ["linkings.group_id IN (#{groups.join(',')}) AND (linkings.linkable_type='Article') AND (articles.title LIKE ? OR articles.body LIKE ? OR (SELECT tags.name FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = articles.id AND taggings.taggable_type = 'Article' AND tags.name LIKE ?) IS NOT NULL)", "%#{query}%", "%#{query}%", "%#{query}%"], :group => "articles.id", :order => order)
    end
  end
  
  protected

  def create_permalink
    self.permalink = title.to_s.gsub(/\W+/, ' ').strip.downcase.gsub(/\ +/, '-') if permalink.blank?
  end

  def convert_to_utc
    self.published_at = published_at.utc if published_at
  end
  
end
