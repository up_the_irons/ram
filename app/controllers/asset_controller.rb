#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
# 
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class AssetController < ProtectedController
  include EnlightenObservers

  observer :change_observer

  @@asset_404 = "The asset could not be found."    

  def show
    @asset = current_user.assets_search({:id=>params[:id]})[0]
    
    if @asset
      redirect_to :action=>'download',:id=>@asset.filename unless @asset.image?
    else
      render :text=>'could not find asset'
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
    @asset = current_user.assets_search({:id=>params[:id]})[0]
    thumb = @asset.thumbnail_size(params[:thumbnail]) if @asset and params[:thumbnail]
    @asset = thumb if thumb
    send_data @asset.data, :filename => @asset.filename, :type => @asset.content_type, :disposition => 'inline'
  end

  #the bulk upload process is initiated from flash.
  def bulk_upload
    # @size_limit = UPLOAD_SIZE_LIMIT #50000*1024
    @size_limit = $APPLICATION_SETTINGS.filesize_limit
    if @category = find_in_users_categories(params[:id])
      @login = CGI.escape(current_user.encrypt_login)
      @url_params = "maxFileSize=#{@size_limit}"
      @url_params = "&onCompleteCallback=show_upload_results"
      @url_params << "&url=#{url_for(:action=>'create_en_masse', :only_path=>true, :id=>@category.id,:hash=>@login)}" 
    end
  end
  
  #called repeatedly through flash
  def create_en_masse
    redirect_to :controller=>'inbox' and return false unless request.post?
    
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
        session[:user] = @user
        @asset.save
      end
      #the js in the view returns the items a comma delimited string and NOT an array like you would expect.
      #so we must convert the string into an array.
      @groups_from_params  = params[:user][:group_ids][0].split(',').map do |g| 
        group = @user.groups.find(g)
        #create_linkage_for(@asset, group) if group
        @asset.groups << group
      end
    end
    render :text=>"\n", :layout=>false
  end
  
  
  def show_upload_results
    #DON'T DELETE THIS METHOD Flash Needs to resolve to it.
  end
  
  def edit
    Asset.with_scope(:find => { :conditions => "user_id = #{current_user.id}", :limit => 1 }) do 
      begin
        @asset = find_asset_by params[:id] if params[:id]
      rescue
        flash[:notice] = 'Could not find asset'
      end
    end
    @asset = Asset.new unless @asset
    
    if @asset.new_record? || @asset.category_id.nil?
      @category =  (params[:category_id])? Category.find(params[:category_id]) : Category.new
    else
      @category = Category.find(@asset.category_id)
    end
    

    if request.post? #nothing else to do below if the request was a get
      @potential_groups = []
      respond_to do |wants|
        wants.html do
          
          #don't allow the user_id to be passed in as a param.
          params[:asset].delete('user_id') unless params[:asset][:user_id].nil?
          @asset.user_id = current_user.id if @asset.new_record?
          unless params[:asset][:group_ids].nil?
            @potential_groups = params[:asset][:group_ids] 
            params[:asset].delete('group_ids')
          end
            
          if @asset.update_attributes(params[:asset])
            @added, @removed  = update_has_many_collection( @asset, 'groups', @potential_groups )
            #display results of the edit in the requested format
            flash[:notice] = "\"#{@asset.filename}\" was saved."
            flash[:notice] << "<br/>Added (#{@added.size}) groups and removed (#{@removed.size})" if defined?(@added) && defined?(@removed)
            redirect_to :action=>'edit', :id=>@asset.id unless params[:id]
          end
          
        end
        wants.js do
          render :update do |page|
            page.replace_html(params[:update],  :partial=>'form')
          end      
        end
        
      end  
    end
  end
  
  def destroy
    raise if request.get?
    @asset = find_asset_by params[:id]
    raise if @asset.nil?
    raise unless current_user.can_edit? @asset
    @category = Category.find(@asset.category_id)
    raise unless accessible_items(@category,'assets',current_user.groups).include?(@asset)
    raise unless @asset.destroy
    
    respond_to do |wants|
      wants.html do
        redirect_to :controller=>'category',:action=>'show', :id=>@asset.category_id
      end
        
      wants.js do
        render :update do |page|
          page.call "grail.notify",{:skin=>"music_video",:subject=>'Success',:body=>"#{@asset.filename} was deleted."}
          page.remove params[:update]
          page.remove params[:update]+"_thumbnail" # Remove the thumbnail too
        end
      end
    end
    
  rescue
    redirect_to :controller=>'inbox', :action=>'index'
    flash[:notice] = @@asset_404
  end
  
  protected
  def find_asset_by(param)
    if params[:id].to_s.match(/^\d+$/)
      asset = Asset.find(param)
    else
      asset = Asset.find_by_name(param)
    end
  end
    
end
