require 'rubygems'
require 'zip/zipfilesystem'

class FolioController < ProtectedController

  verify :method => :post, :only => [ :add, :remove, :remove_all ],
         :redirect_to => { :action => :index }
  def index
    redirect_to :action=>'list'
  end
  
  
  def list
      @assets = []
    if session[:folio].empty?
      flash[:notice] = "Your folio is empty." 
    else
      session[:folio].map do |a| 
        begin
          asset = Asset.find(a)
          @assets << asset if asset
        rescue
          session[:folio].delete(a)
          flash[:notice] = "Could not find asset using the id of #{a}"
        end
      end
    end
  end
  
  def add

    @asset = find_asset_for_group_member(params[:group_id].to_i,params[:asset_id].to_i) if params[:group_id]
    @asset = find_asset_in_category_for_group_member(params[:category_id].to_i,params[:asset_id].to_i) if params[:category_id]
    unless @asset.nil?
      unless session[:folio].include? @asset.id
        flash[:notice] = "#{@asset.name} was added to your folio"
        session[:folio] << @asset.id
      else
         flash[:notice] = "#{@asset.name} is already in your folio"
      end 
    else
      flash[:notice] = "The requested asset could not be located on the server."
    end
     
    respond_to do |wants|
      wants.html do
        index
      end
      wants.js do 
        render :update do |page|
        #todo ajax removal
        end
      end
    end
  end
  
  def remove
    unless params[:id].nil?
      unless session[:folio].delete(params[:id].to_i).nil?
        flash[:notice] = "You removed the file from your folio."
      else
        flash[:notice] = "File was not removed from folio."
      end  
    end
    redirect_to :action=>'list'
  end
  
  def remove_all
    session[:folio].clear
    flash[:notice] = "You emptied your folio"
    redirect_to :action=>'list'
  end
  
  #TODO: Create some sweeper event, which will remove zip files after a certain amount of time.
  def zip
      @zip_file = "#{RAILS_ROOT}/downloads/#{current_user.login}_folio_#{(Time.now).to_i}.zip"
    if create_zip(@zip_file)
      send_file @zip_file
    else
      render :text=>'error creating zip of folio'
    end
  end
  
  protected
  def create_zip(path)
    Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zip|
      zip.dir.mkdir('folio')
      session[:folio].map do | a |
        asset = Asset.find a
        zip.file.open("folio/#{asset.filename}", 'w'){|file| file << asset.data } unless asset.nil?
      end
    end
  end
  
  def find_asset_in_category_for_group_member(category_id = nil, asset_id = nil)
    current_user.categories.map do |c|
      if c.id == category_id
        c.assets.map do |a|
          return a if a.id == asset_id
        end
      end
    end
  end
  
  def find_asset_for_group_member(group_id = nil, asset_id = nil)
    current_user.groups.map do |g| 
      if g.id == group_id
        g.assets.map do |a|
          return a if a.id == asset_id
        end
      end
    end
    nil
  end
end
