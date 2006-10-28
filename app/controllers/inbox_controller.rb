require 'ostruct'
class InboxController < ProtectedController
  include FeedReader
  def index
    inbox
  end
  
  def inbox
    @feeds =[]
    @messages = []
    current_user.feeds.map{|f| @feeds << RSS::Parser.parse(f.data,false) if f.is_local}
    @feeds.each do |feed|
      feed.channel.items.each do |i|
        # Format the feed items like messages so that they can be displayed in the inbox.
        @messages << OpenStruct.new(
                    :body=>i.description,
                    :subject=> i.title,
                    :id=>feed.id,
                    :created_at=>i.pubDate
                    )
      end
    end
    @messages << Event.find_all_by_recipient_id(current_user.id, :order => @order).flatten
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
    return unless request.post? # Get cannot do anything below this point
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
          #page.replace_html(params[:update],  :partial=>'feed_form')  unless @feed.valid?
          page.redirect_to :controller=>'inbox', :action=>'edit_feed'
          # page.redirect_to :controller=>'inbox', :action=>'inbox' if @feed.valid?
        end      
      end
    end
    
  end
  
  def read_article
    url = current_user.feeds.map{|f| f.url}[params[:channel_id].to_i]
    @item = feed_item(url,params[:item_id])
    respond_to do |wants|     
      wants.html do
      end 
      #render inline RJS as responce
      wants.js do 
        render :update do |page|
          #TODO replace the onclick handler so that we don't have to load the messages again
          page.replace_html(params[:update],  :partial=>'feed_item',:locals=>{:item=>@item})
        end
      end
    end
  end
  
  
  def subscribe_feed
    if request.post?
      @feed = Feed.find_or_create_by_local_path_and_name_and_is_local(params[:local_path], params[:name],true)
      if @feed.valid?
        @feed.subscribers << current_user
        flash[:notice] = "You are now subscribed to #{@feed.name}"
      else
        flash[:error] = "There was an error creating your subscription."
      end
    end
    redirect_to :action=>'inbox'
  end
  
  
  def unsubscribe_feed
    begin
      feed = Feed.find(params[:id])
    rescue
      flash[:error] = "Could not find Feed"
    end
    feed.subscribers.unsubscribe current_user if feed and request.post?
    redirect_to :action=>'inbox'
  end
  
end
