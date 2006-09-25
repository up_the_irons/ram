class AssetController < ProtectedController

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update,:create_en_masse ],
         :redirect_to => { :action => :index }
         
  def show
    #TODO: scope this call
    @asset = Asset.find(params[:id])
    
    if @asset.image?
      #send_data @asset.data, :filename => @asset.filename, :type => @asset.content_type, :disposition => 'inline'
      
    else
      redirect_to :action=>'download',:id=>@asset.filename
    end
  end
  
  def download
    #scope this call.
    @asset = Asset.find_by_filename(params[:id])
    if @asset
      headers['Content-Type'] = @asset.content_type
      render :text => @asset.data
    else
      render :text=>'could not find asset'
    end
  end
  
  def show_inline
    #TODO :Scope this call.
    @asset = Asset.find(params[:id])
    send_data @asset.data, :filename => @asset.filename, :type => @asset.content_type, :disposition => 'inline'
  end

  #the bulk upload process is initiated from flash.
  def bulk_upload
    @size_limit = UPLOAD_SIZE_LIMIT #50000*1024
    if @category = find_in_users_categories(params[:id])
      @login = CGI.escape(current_user.encrypt_login)
      @url_params = "maxFileSize=#{@size_limit}"
      @url_params = "&onCompleteCallback=show_upload_results"
      @url_params << "&url=#{url_for(:action=>'create_en_masse', :only_path=>true, :id=>@category.id,:hash=>@login)}" 
    end
  end
  
  #called repeatedly through flash
  def create_en_masse
    @login = User.decrypt_string(params[:hash])
    unless @login.nil?
      @user = User.find_by_login(@login)
      if @user
        @asset = Asset.new({
                            "category_id"=>params[:id], 
                            "description"=>'',
                            "user_id"=>@user.id
                            })
        
        @asset.uploaded_data = Asset.translate_flash_post @params[:Filedata]
        @asset.save
      end
      #the js in the view returns the items a comma delimited string and NOT an array like you would expect.
      #so we must convert the string into an array.
      @groups_from_params  = params[:user][:group_ids][0].split(',').map do |g| 
        group = @user.groups.find(g)
        create_linkage_for(@asset, group) if group
      end
    end
    render :text=>"\n", :layout=>false
  end
  
  
  def show_upload_results
    #DON'T DELETE THIS METHOD Flash Needs to resolve to it.
  end
  
  def edit
    @asset = Asset.find_by_id(params[:id]) || Asset.new
    @category = find_in_users_categories(params[:category_id])
    #@remaining_groups = current_user.groups - @asset.groups
    @assigned_groups,  @remaining_groups = find_assigned_and_remaining_groups current_user.groups, @asset.groups
    return unless request.post?
    #submit
    @action = 'update'
    respond_to do |wants|
      wants.js do 
        render :update do |page|
          page.replace_html(params[:update],  :partial=>'form')
          #IE has problems rendering the BlindDown
          #page.visual_effect :BlindDown , params[:update], :duration=>1
        end
      end
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

    #todo scope this find
    return unless request.post?

      @asset = Asset.find_by_id(params[:id])
      @group = find_in_users_groups params[:group_id]
      @category = find_in_users_categories params[:category_id]
      unless @asset.nil? || @group.nil? || @category.nil?

        @link = Linking.find_or_create_by_linkable_id_and_linkable_type_and_category_id_and_group_id(@asset.id,'Asset',@category.id,@group.id)
        @link.save!
        
        unless @link.nil?
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
          #error creating linking
        end
      else
        #could not find needed elements to create the linking raise exception
        render :text=>'could not find something.', :layout=>false
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
          wants.html do
            flash[:notice] = "Asset was saved"
            redirect_to :controller=>'category', :action=>'show', :id=>params[:category_id]
          end
          wants.js do 
            render :update do |page|
              #TODO There is a bug with Safari and this event, It renders the response inline as text instead of executing javascript. maybe it has something to do with the post
              page.replace_html(params[:update],  'Asset was saved.')
            end
          end
        end
      else
        flash[:error] = "Could not save your asset."
        redirect_to :controller=>'category', :action=>'show', :id=>params[:category_id]
      end
    end
  end
  
  def cancel_update
    respond_to do |wants|
      wants.js do 
        render :update do |page|
          #page.visual_effect :BlindUp , params[:update], :duration=>1
        end
      end
      wants.html do |wants|
        redirect_to :controller=>'category', :action=>'show', :id=>params[:id] if find_in_users_categories params[:id]      
      end
    end
  end
  
  def destroy
    return unless request.post?
    @asset = Asset.find(params[:id])
    #Linking.destroy_all "linkable_id" == @asset.id
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
  
  protected
  def find_assigned_and_remaining_groups(users_groups, assets_groups)
    restricted_assigned_groups = assets_groups - users_groups
    assigned = assets_groups - restricted_assigned_groups
    remaining = users_groups - assigned 
    return [assigned,remaining]
  end
    
  def create_linkage_for(asset,group)
    @link = Linking.find_or_create_by_linkable_id_and_linkable_type_and_group_id(asset.id,'Asset',group.id)
    @link.save!
  end
    
end
