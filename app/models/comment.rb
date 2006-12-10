#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

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
