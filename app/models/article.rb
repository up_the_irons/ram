# Schema as of Sat Sep 02 01:11:01 PDT 2006 (schema version 15)
#
#  id                  :integer(11)   not null
#  parent_id           :integer(11)   
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

class Article < ActiveRecord::Base
  acts_as_tree
  acts_as_taggable
  validates_presence_of   :user_id, :body,:title, :message=>'cannot be blank'
  has_many :comments, :dependent => true, :order => "created_at ASC"
  belongs_to :user
  has_one :category
  
  #snipped from mephisto (http://www.mephistoblog.com/)
  after_validation :convert_to_utc
  before_create :create_permalink
  
  def comments
    self.children
  end
  
  
  #snipped from mephisto's post model (http://www.mephistoblog.com/)
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
    self.save!
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
  
  protected
    def create_permalink
      self.permalink = title.to_s.gsub(/\W+/, ' ').strip.downcase.gsub(/\ +/, '-') if permalink.blank?
    end

    def convert_to_utc
      self.published_at = published_at.utc if published_at
    end
  
end
