#basic RSS aggregator mixin.
#takes a valid RSS feed (not Atom feed) and parses each item of the feed into an instance of the RSS::Rss::Channel::Item class.
#the class has these instance_varialbes [@guid, @author, @title, @converter, @category, @description, @link, @enclosure, @source, @do_validate, @pubDate, @comments]

require 'rss/2.0'
require 'open-uri'
require 'initializable'
module FeedReader
  include Initializable #when including this module DONOT call the self.included callback because it will override Initializable
  
  def self.initialize(class_instance)

    #inject the needed instance variables for the feedreader. The initializable module takes care of the auto loading of this module within the mixee class
    #however, you still need to do a instance_eval to set the needed variables for the feed_reader functionality.
    [{:key=>'feeds',:value=>[]}, {:key=>'feed_urls',:value=>[]}].each do |h|
      
      #generic accessor for instance_variables
      attr_accessor "#{h[:key].to_sym}"

      #only create these instance variabes if they don't already exisit in the mixee class.
      class_instance.instance_eval do
        instance_var = "@#{h[:key]}"
        class_instance.instance_variable_set(instance_var.to_sym, h[:value] ) unless class_instance.instance_variables.include?(instance_var)
      end
    end
    
    class_instance.instance_eval{read_feeds unless @feed_urls.empty?}
  end
  
  protected
  def read_feeds
    @feed_urls.each{|url| @feeds.push(RSS::Parser.parse(open(url).read,false)) }
  end
  
  public
  def refresh
    @feeds.clear
  end
  
  def channel_counts
    @feeds.each_with_index do |feed, index|
      channel = "===Channel(#{index.to_s}): #{feed.channel.title}==="
      articles = "Articles: #{feed.items.size.to_s}"
      puts channel + ", " + articles
    end
  end
  
  def list_articles(id)
    puts "=== Channel(#{id.to_s}): #{@feeds[id].channel.title}==="
    @feeds[id].items.each { |item| puts " " + item.title }
  end
  
  def list_all
    @feeds.each_with_index{|f,i| list_articles(i)}
  end
  
end