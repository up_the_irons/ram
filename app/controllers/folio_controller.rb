require 'rubygems'
require 'zip/zipfilesystem'

class FolioController < ProtectedController
  include Sortable

  verify :method => :post, :only => [ :add, :remove, :remove_all ],
         :redirect_to => { :action => :index }

  sortable :list

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

    # When we lack SQL being able to sort for us, we do it w/ Ruby!
    if @order
      column, direction = @order.split(' ')
      @assets.sort! do |a,b|

        # If both args are not nil, we can just use <=> and be done with it
        if a[column] && b[column]
          case direction
          when 'asc'  then a[column] <=> b[column]
          when 'desc' then b[column] <=> a[column]
          end

        # Otherwise, we have to decide what is less than / greater than nil manually  
        else
          if !a[column] and !b[column]
            0
          elsif a[column]
            direction == 'asc' ? 1 : -1
          elsif b[column]
            direction == 'asc' ? -1 : 1
          end
        end
      end
    end

    respond_to do |wants|
      wants.js do
        render :update do |page|
          page.replace_html :asset_list, :partial => 'asset/list'
        end
      end
      wants.html
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
      zip.dir.mkdir('folio') #acts as the root folder
      session[:folio].map do | a |
        asset = Asset.find a
        unless asset.nil?
          path = "folio/#{create_category_tree(asset.category_id)}"
          zip.dir.mkdir(path) unless zip.entries.find{|x| x.name =~ /#{path}/}
          zip.file.open("#{path}#{asset.filename}", 'w'){|file| file << asset.data }
        end
      end
    end
  end
  
  #assumes that the user has logged in and assigned an access-scoped category tree
  def create_category_tree(category_id)
    @path = ""
    tree = current_user.categories_as_tree
    cat = tree["b_#{category_id}".to_sym]
    while cat[:parent] != :root
      @path =  "#{cat[:name]}/" << @path
      cat = tree[cat[:parent]]
    end
    @path = @path.gsub(/\ +/, '-').downcase #remove white spaces from filenames
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
