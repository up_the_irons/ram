#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

# Schema as of Fri Oct 27 20:31:51 PDT 2006 (schema version 22)
#
#  id                  :integer(11)   not null
#  parent_id           :integer(11)   
#  category_id         :integer(11)   
#  user_id             :integer(11)   
#  title               :string(255)   
#  permalink           :string(255)   
#  excerpt             :text          
#  body                :text          
#  excerpt_html        :text          
#  body_html           :text          
#  created_at          :datetime      
#  updated_at          :datetime      
#  published_at        :datetime      
#  children_count      :integer(11)   
#  type                :string(255)   
#  allow_comments      :boolean(1)    
#  status              :integer(11)   default(0), not null
#

class Comment < Article
  belongs_to :article, :counter_cache => "children_count"
  has_one :user
  
  def validate
    if parent_id
      errors.add_to_base("Comments are not allowed.") unless Article.find(parent_id).allow_comments? 
    end
  end
  
  validates_presence_of :body
end
