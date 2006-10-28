# Schema as of Fri Oct 27 20:31:51 PDT 2006 (schema version 22)
#
#  id                  :integer(11)   not null
#  url                 :string(255)   
#  name                :string(255)   
#  created_at          :datetime      
#  updated_at          :datetime      
#  is_local            :boolean(1)    default(true)
#  local_path          :string(255)   
#
require 'rss/2.0'
class Feed < ActiveRecord::Base
  acts_as_subscribable
  
  def title
    name
  end
  
  def is_local?
    is_local
  end
  
  def data
    rss = create_rss_from local_path if is_local
  end
  
  protected
  def create_rss_from(path="")
    path_parts = local_path.split('/')
    id = path_parts.pop
    klass = path_parts.pop.classify.constantize
    @model = klass.find(id)
    
    rss = RSS::Rss.new("2.0")
    chan = RSS::Rss::Channel.new
    chan.title = name
    chan.description = @model.description
    chan.link = local_path
    rss.channel = chan
    
    contents = []    
    contents << @model.changes if @model.respond_to?('changes')
    contents = contents.flatten
    contents.each do |item|
      chan.items << create_channel_item(item)
    end
    rss.to_s
  end
  
  def create_channel_item(item)
    chan_item = RSS::Rss::Channel::Item.new
    chan_item.title = "#{item.name}"
    chan_item.description = item.description
    chan_item.pubDate = item.created_at
    chan_item
  end
  
  def validate
    unless is_local
      # Validate format
      errors.add(:url) unless url =~ /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix
      
      # Validate uniqueness with local_path conditions
      feed = Feed.find_by_name_and_local_path(name,local_path)
      errors.add_to_base("The feed must be unique.") if feed && feed.id != id
    else
      # Validate uniqueness with remote conditions
      feed = Feed.find_by_name_and_url(name,url)
      errors.add_to_base("The feed must be unique.") if feed && feed.id != id 
    end
  end
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope=> :url
end
