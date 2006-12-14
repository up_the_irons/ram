#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett, Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class InboxController < ProtectedController
  include FeedReader

  def index
    inbox
  end
  
  def inbox
    @feeds    = []
    @messages = []

    # We need to store the feed's ID in the hash because the RSS instance's ID will map to an internal memory
    # location not an active record object.
    current_user.feeds.map { |f| @feeds << { :feed => RSS::Parser.parse(f.data, false), :id => f.id } if f.is_local }

    @feeds.each do |feed_hash|
      feed_hash[:feed].channel.items.each_with_index do |i,index|
        # Format the feed items like messages so that they can be displayed in the inbox.
        # I need need to include the link to the feed and the item of the feed as the id, 
        # because the feed item gets a "new" id each time it is loaded unfortunately.
        id = "#{feed_hash[:id]}__#{index}"
        @messages << OpenStruct.new(
                      :body => i.description,
                      :subject => i.title,
                      :created_at => i.pubDate,
                      :params => { :message_type => 'Feed', :controller => 'inbox', :action => 'read_feed_item', :id => id })
      end
    end

    @messages << (Event.find_all_by_recipient_id(current_user.id, :order => @order).flatten).each{|m| m[:params] = {:message_type => "Event", :controller => "events"}}
    @messages = @messages.flatten

    render 'inbox/inbox'
  end
  
  def edit_feed
    # TODO: Scope this call.
    begin
      @feed = Feed.find(params[:id]) if params[:id]
    rescue
      flash[:error] = "Could not find Feed"
    end
    
    @feed = Feed.new unless @feed
    return unless request.post? # GET cannot do anything below this point

    unless params[:feed].nil?
      @feed.update_attributes params[:feed] 
      current_user.feeds << @feed if @feed.valid?
      flash[:notice] = "You subscribed to #{@feed.name}"
    end
    
    respond_to do |wants|
      wants.html do
      end
      wants.js do
        render :update do |page|
          page.redirect_to :controller=>'inbox', :action=>'edit_feed'
        end      
      end
    end
    
  end
  
  def read_article
    url = current_user.feeds.map{ |f| f.url }[params[:channel_id].to_i]
    @item = feed_item(url, params[:item_id])

    respond_to do |wants|     
      wants.html do
      end 
      # Render inline RJS as response
      wants.js do 
        render :update do |page|
          # TODO: Replace the onclick handler so that we don't have to load the messages again
          page.replace_html(params[:update],  :partial => 'feed_item', :locals => { :item => @item })
        end
      end
    end
  end
  
  def subscribe_feed
    if request.post?
      @feed = Feed.find_or_create_by_local_path_and_name_and_is_local(params[:local_path], params[:name], true)
      if @feed.valid?
        @feed.users << current_user
        flash[:notice] = "You are now subscribed to #{@feed.name}"
      else
        flash[:error] = "There was an error creating your subscription."
      end
    end
    redirect_to :action => 'inbox'
  end
  
  def read_feed
    redirect_to(:controller => 'inbox', :action => 'inbox') and return false unless params[:id]
    begin
      @feed = Feed.find(params[:id])
      @data = RSS::Parser.parse(@feed.data,false) if @feed.is_local
    rescue
      flash[:error] = "Could not find feed."
      redirect_to(:controller => 'inbox', :action => 'inbox') and return false unless @feed
    end
    @messages = []
    @data.channel.items.each do |i|
      # Format the feed items like messages so that they can be displayed in the inbox.
      @messages << OpenStruct.new(
          :body => i.description,
          :subject => i.title,
          :id => @data.id,
          :created_at => i.pubDate
      )
    end
    @messages
    render 'inbox/inbox'
  end
  
  # The feed items take a special formating syntax because the RSS class does not contain an id like the decendents of active record.
  # to ensure we load the correct feed the inbox method passes the id in this format "#{feed id}_#{ index for item}".
  def read_feed_item
    return false unless params[:id]
    arr = params[:id].split("__")
    
    current_user.feeds.map{|f| @feed = f if f.id == arr[0].to_i }
    @rss = RSS::Parser.parse(@feed.data, false) if @feed.is_local
    id = arr[1].to_i
    @item = @rss.items[id]

    # convert the format of the RSS item into a "post", which the template wants.
    @post = OpenStruct.new(
      :id => id,
      :author => "System Message",
      :typeof => 'Feed',
      :body => @item.description,
      :created_at => @item.pubDate.strftime("%m/%d/%Y")
    ) if @item

    render :update do |page|
      page.toggle       "message_body_container_#{params[:id]}"
      page.replace_html "message_body_#{params[:id]}", :partial => 'shared/post', :locals => { :post => @post }

      # Replace the onclick handler that got us here with a simple element toggler. We already have the msg
      # body loaded, so we don't need to call this action again.
      page << "$(Content.cache.push($('message_body_container_#{params[:id]}')))"
    end if @post
  end
  
  def unsubscribe_feed
    begin
      feed = Feed.find(params[:id])
    rescue
      flash[:error] = "Could not find Feed"
    end
    if feed and request.post?
      feed.users.delete current_user
      flash[:notice] = "Your request to unsubscribe was successful."
    end
    redirect_to :action=>'inbox'
  end
  
end
