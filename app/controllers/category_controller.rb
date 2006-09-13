class CategoryController < ProtectedController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  #verify :method => :post, :only => [ :destroy, :create, :update ],
  #       :redirect_to => { :action => :list }

  def list
    @category_pages, @categories = paginate_collection current_user.categories, :page => @params[:page]
  end

  def show
    #TODO "Confirm that the responds_to is actually working, I think it is not"
    respond_to do |wants|
      wants.html do
        #only show if this category appears inside the user's list of categories
        @category = find_in_users_categories(params[:id])
        
        @good_assets = []
        @groups = @category.groups & current_user.groups
        #@assets = @category.assets.find(:all, :conditions => ["linkable_type='Asset' AND category_id=#{@category.id} AND group_id IN (?)", @groups.collect{|g| g.id}.join(",")])
        #@total_assets = @category.assets.find(:all).uniq
        #@or_conditions = @groups[1..@groups.length].map{|g| "OR group_id=#{g.id}"}
        @assets = @category.assets
          
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

 # def new
 #   @category = Category.new
 # end
 #
 # def create
 #   case request.method
 #     when :get
 #       @category = Category.new
 #       render :action=> 'new'
 #     when :post
 #       @category = Category.create(params[:category])
 # 	    @category.user_id = current_user
 # 	    @category.save
 #       if @category.save
 #         flash[:notice] = 'Category was successfully created.'
 #         redirect_to :action => 'list'
 #       else
 #         render :action => 'new'
 #       end
 #   end
 # end

 # def edit
 #   #@category = Category.find(params[:id])
 #   @category = find_in_users_categories(params[:id])
 # end
  
  #def show_asset_form
  # 
  #  #@category = Category.find(params[:id])
  #  @category = find_in_users_categories(params[:id])
  #  @asset = Asset.new
  #  
  #  # todo scope this to the user's group list
  #  @groups = @category.groups & current_user.groups
  #  puts @category.to_yaml
  #  render :update do |page|
  #    if(@groups.empty?)
  #      page.replace_html(params[:update],  'There are no groups with access to this category.')
  #    else
  #      page.replace_html(params[:update], :partial=>'new_asset_form')
  #    end 
  #  end
  #end
  
  #def create_and_add_asset
  #  #puts params.to_yaml
  #  #todo: find some way to inform the user that they were successful adding the asset but failed to add it to one of (n) groups
  #  @category = find_in_users_categories params[:category_id]
  #  unless @category.nil?
  #     @asset = Asset.new(params[:asset])
  #     @asset.user_id = current_user
  #     if @asset.save
  #       for g in params[:groups]
  #         @group = find_in_users_groups g
  #         #puts @group.to_yaml
  #          unless @group.nil?
  #            @linking = Linking.create(
  #            {
  #            :group_id=>@group.id, 
  #        		:category_id=>@category.id, 
  #        		:user_id=>current_user,
  #        		:linkable_id=>@asset.id,
  #        		:linkable_type=>'Asset'
  #      		  }
  #            )
  #          else
  #            #group was not found in user's access privilages.
  #            render :text=>'group not found' and return
  #          end
  #        end
  #        flash[:notice] = 'Asset was successfully created.'
  #        redirect_to :controller=>"category",:action=>"show",:id=>@linking.category_id
  #      else
  #          #error creating asset
  #          render :text=>'error creating asset' and return
  #      end
  #  else
  #    #category was not found in user's category list
  #    render :text=>'category not found' and return
  #  end
  #end
  
  #def cancel_create_and_add_asset
  #  #@category = Category.find(params[:id])
  #  @category = find_in_users_categories(params[:id])
  #  render :update do |page|
  #    page.replace_html(params[:update], :partial=>'new_asset_button')
  #    page.visual_effect :highlight, params[:update], :duration=>1
  #  end
  #end
  
 # def show_group_form  
 #   #@category = Category.find(params[:id])
 #   @category = find_in_users_categories(params[:id])
 #   
 #   #@groups = Group.find(:all) - @category.groups
 #   @groups = current_user.groups - @category.groups
 #   render :update do |page|
 #     if(@groups.empty?)
 #       page.replace_html(params[:update],  'All of your groups already have access to this category.')
 #     else  
 #       page.replace_html(params[:update], :partial=>'new_group_form',:locals=>{:groups=>@groups.map{|g| [g.name , g.id] } })
 #     end
 #     page.visual_effect :highlight, params[:update], :duration=>1
 #   end
 # end
  
 

 #def update
 #  #@category = Category.find(params[:id])
 #  @category = find_in_users_categories(params[:id])
 #  if @category.update_attributes(params[:category])
 #    flash[:notice] = 'Category was successfully updated.'
 #    redirect_to :action => 'show', :id => @category
 #  else
 #    render :action => 'edit'
 #  end
 #end

#def destroy
#  #Category.find(params[:id]).destroy
#  find_in_users_categories(params[:id]).destroy
#  redirect_to :action => 'list'
#end
  
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
