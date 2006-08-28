class AssetController < ProtectedController
  
  def index
  
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }
         
  def show
    @asset = Asset.find(params[:id])
    
    if @asset.image?
      #send_data @asset.data, :filename => @asset.filename, :type => @asset.content_type, :disposition => 'inline'
      
    else
       headers['Content-Type'] = @asset.content_type
       render :text => @asset.data
    end
  end
  
  def show_inline
    @asset = Asset.find(params[:id])
    send_data @asset.data, :filename => @asset.filename, :type => @asset.content_type, :disposition => 'inline'
  end
  
  #def new
  #  #c = Category.find(params[:category])
  #  c = find_in_users_categories(params[:category])
  #  @asset = Asset.new
  #  @linking = Linking.new
  #  #TODO validate that the user does have access to this category and group and did not spoof the request
  #  @linking.category_id = c.id
    
  #  #TODO Don't hard code this.
  #  @linking.group_id = c.groups[0].id
  #end
  
  #def create
  #  #render :text=>"<pre>#{params.to_yaml}</pre>", :layout=>'application'
  #  
  #  
  #  @asset = Asset.new(params[:asset])
  #	@asset.user_id = current_user
  #  if @asset.save
  #    #you search for an existing linking first because creating a new linking that is not unique will cause an exeception.
  #    #@linking = Linking.find_or_create_by_category_id_and_group_id(params[:linking]['category_id'], params[:linking]['group_id'])
  #    @linking = Linking.create(params[:linking])
  #    @linking.user_id = current_user
  #    @linking.linkable_id = @asset.id
  #    @linking.linkable_type = 'Asset'
  #    @linking.save
  #    flash[:notice] = 'Asset was successfully created.'
  #    redirect_to :controller=>"category",:action=>"show",:id=>@linking.category_id
  #    else
  #      render :action => 'new'
  #    end
  #end

  
  
  def edit
    @asset = Asset.find_by_id(params[:id]) || Asset.new
    @category = find_in_users_categories(params[:category_id])
    #@remaining_groups = current_user.groups - @asset.groups
    @assigned_groups,  @remaining_groups = find_assigned_and_remaining_groups current_user.groups, @asset.groups
    #todo: find a way to scope this group list
    if request.post?
      #submit
      @action = 'update'
      respond_to do |wants|
        wants.js do 
          render :update do |page|
            page.replace_html(params[:update],  :partial=>'form')
            page.visual_effect :BlindDown , params[:update], :duration=>1
          end
        end
      end
    else
      #get request
    end
  end
  
  def remove_group
    if request.post?
      #todo scope this find
      @asset = Asset.find_by_id(params[:id])
      unless @asset.nil?
        Linking.find_by_group_id_and_linkable_id_and_category_id(params[:group_id],@asset.id, params[:category_id]).destroy
        
        #todo if this is the last group then also delete the asset.
        
        respond_to do |wants|
          wants.js do 
            render :update do |page|
              page.visual_effect :puff, params[:update], :duration=>1
            end
          end
        end
      end
    end
  end
  
  def add_group
    logger.warn "\n*************************ADD A GROUP***********************\n"
    #todo scope this find
    if request.post?
      logger.warn "\n*************************POST METHOD***********************\n"
      @asset = Asset.find_by_id(params[:id])
      @group = find_in_users_groups params[:group_id]
      @category = find_in_users_categories params[:category_id]
      unless @asset.nil? || @group.nil? || @category.nil?
        logger.warn "\n*************************ASSET GROUP CATEGORY FOUND***********************\n"
        @link = Linking.find_or_create_by_linkable_id_and_linkable_type_and_category_id_and_group_id(@asset.id,'Asset',@category.id,@group.id)
        @link.save!
        logger.warn "#{@link.to_yaml}"
        unless @link.nil?
           logger.warn "\n*************************LINKING SAVED***********************\n"
          respond_to do |wants|
            wants.js do
              flash[:notice] = 'Your Group has been added'
              render :update do |page|
                page.insert_html(  :bottom    , "asset_form_group_list", :partial=>'group_item',:locals=>{:group=>@group})
                page.visual_effect :highlight , "group_#{@group.id}", :duration=>1
                page.visual_effect :highlight , params[:update], :duration=>1
                page.replace_html('page_flash', flash[:notice] )
              end
            end
          end
        else
           logger.warn "\n*************************LINKING COULD NOT BE SAVED***********************\n"
          #error creating linking
        end
      else
        logger.warn "\n*************************ASSET GROUP CATEGORY NOT FOUND***********************\n"
        logger.warn "asset"
        logger.warn "#{@asset.to_yaml}"
        logger.warn "category"
        logger.warn "#{@category.to_yaml}"
        logger.warn "group"
        logger.warn "#{@group.to_yaml}"
        #could not find needed elements to create the linking raise exception
        render :text=>'could not find something.', :layout=>false
      end
    else
      #was a get instead of a post.
      logger.warn 'GET**************'
      render :update do |page|
        page.alert 'foo'
      end
    end
  end
  
  #replaces modifications of exisitng records
  def update
    @asset = Asset.find_by_id(params[:id]) || Asset.new
    @action = 'update'
    @category = find_in_users_categories(params[:category_id])
    @asset.category = @category
    @groups = @asset.groups - current_user.groups || current_user.groups unless @asset.new_record?
    params[:groups] = current_user.groups.map{|g| g.id } if @asset.new_record?
    if request.post?
      @asset.user_id = current_user
      @asset.attributes = params[:asset]
      if @asset.save
        @groups = @asset.groups
        #todo this only adds groups we need to remove them too if the user wants to delete a group.

        for g in params[:groups]
           group = find_in_users_groups g
            unless group.nil?
              #holy crap!
              @linking = Linking.find_or_create_by_group_id_and_category_id_and_linkable_id_and_linkable_type(group.id, @category.id, @asset.id,'Asset')
            else
              #group was not found in user's access privilages.
              #raise exception here.
              render :text=>'group not found' and return
            end
        end unless params[:groups].nil?
        respond_to do |wants|
          wants.js do 
            render :update do |page|
              #TODO There is a bug with Safari and this event, It renders the response inline as text instead of executing javascript. maybe it has something to do with the post?
              page.replace_html(params[:update],  'Asset was saved.')
            end
          end
          #wants.html do |wants|
          #  flash[:notice] = 'Asset has been saved.'
          #  redirect_to :controller=>'category', :action=>'show', :id=>@category.id 
          #end
        end
      end
    end
  end
  
  def cancel_update
    respond_to do |wants|
      wants.js do 
        render :update do |page|
          page.visual_effect :BlindUp , params[:update], :duration=>1
        end
      end
      wants.html do |wants|
        redirect_to :controller=>'category', :action=>'show', :id=>params[:id] if find_in_users_categories params[:id]      
      end
    end
  end
  
  def destroy
    if request.post?
      @asset = Asset.find(params[:id])
      Linking.destroy_all "linkable_id" == @asset.id
      @asset.destroy
      respond_to do |wants|
        wants.html do 
          redirect_to :controller=>'category', :action => 'show', :id=>params[:category_id] 
        end
        wants.js do 
          render :update do |page|
            page.remove params[:update]
            page.replace_html 'new_asset_form', ''
            page.replace_html 'page_flash', 'You deleted the asset.'
          end
        end
      end
    end
  end
  
  protected
  def find_assigned_and_remaining_groups(users_groups, assets_groups)
    restricted_assigned_groups = assets_groups - users_groups
    assigned = assets_groups - restricted_assigned_groups
    remaining = users_groups - assigned 
    return [assigned,remaining]
  end
  
end
