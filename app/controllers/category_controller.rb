class CategoryController < ProtectedController
    
  def index
    list
  end


  def list
    @category_pages, @categories = paginate_collection current_user.categories, :page => @params[:page]
    render :partial=>'category/list', :layout=>'application'
  end

  def show
    #TODO "Confirm that the responds_to is actually working, I think it is not"
    respond_to do |wants|
      wants.html do
        #only show if this category appears inside the user's list of categories
        @category = find_in_users_categories(params[:id])
        
        @good_assets = []
        @groups   = @category.groups & current_user.groups
        @assets   = @category.assets
        @articles = @category.articles  #TODO: This needs to be scoped to a group in the same way assets are.
        
        @assets.each do |asset|
          @good_assets << asset unless (asset.groups & @groups).empty?
        end
        @assets = @good_assets
      end
      wants.js do 
        render :update do |page|
          page.redirect_to :action=>'show',:id=>params[:id]
        end
      end
    end
  rescue 
    redirect_to :controller=>'inbox'
    flash[:notice] = 'This category could not be found in your access list'
  end
  
  def feed
    #only show if this category appears inside the user's list of categories
    @category = find_in_users_categories(params[:id])
    unless @category.nil? 
      @groups = @category.groups & current_user.groups
      @total_assets = @category.assets.find(:all).uniq
      @or_conditions = @groups[1..@groups.length].map{|g| "OR group_id=#{g.id}"}
      @assets = @category.assets.find(:all, :conditions=>"linkable_type='Asset' AND category_id=#{@category.id} AND group_id=#{@groups[0].id} #{@or_conditions}").uniq
      @feed = FeedTools::Feed.new
      @feed.title = @category.name
      @feed.subtitle = @category.description
      @feed.author = @category.user_id
      @feed.link = url_for(:collection=>'category',:action => 'show', :id => @category.id, :only_path => false)
      
      @assets.each do |a|
        e = FeedTools::FeedItem.new
        e.title = a.filename || "Asset #{a.id}"
        e.link = url_for(:controller=>'asset',:action=>'show',:id=>a.id, :only_path=>false)
        e.content = a.description || ""
        @feed.entries << e
      end
      render :layout=>false
    else
      render :text=>'This category could not be found in your access list'
    end
  end
  
end
