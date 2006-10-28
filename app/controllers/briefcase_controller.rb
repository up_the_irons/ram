require 'rubygems'
require 'zip/zipfilesystem'

class BriefcaseController < ProtectedController
  include Sortable

  verify :method => :post, :only => [ :add, :remove, :remove_all ],
         :redirect_to => { :action => :index }

  sortable :list

  def index
    redirect_to :action=>'list'
  end
  
  def list
    @assets = []
    if session[:briefcase].empty?
      flash[:notice] = "Your briefcase is empty." 
    else
      session[:briefcase].map do |a| 
        begin
          asset = Asset.find(a)
          @assets << asset if asset
        rescue
          session[:briefcase].delete(a)
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
  end
  
  def add
    unless params[:assets].nil?
      new_assets = []
      existing_assets = []
      assets = params[:assets].uniq
      assets.each do | a |
        asset = Asset.find(a)
        unless asset.nil?
          n, e = add_to_briefcase(asset) if current_user.assets.include?(asset)
          new_assets << n unless n.nil?
          existing_assets << e unless e.nil?
        end
      end
      flash[:notice] = ""
      flash[:notice] << "Added (#{new_assets.size}) New Assets.<br/>" unless new_assets.empty?
      flash[:notice] << "(#{existing_assets.size}) Assets could not be added because they already exist.<br/>" unless existing_assets.empty?
    else
      flash[:notice] = "You must select at least one file."
    end
    render_list
  end
  
  
  def add_to_briefcase(asset)
    results = [nil,nil]
    unless session[:briefcase].include? asset.id
      results[0] = asset.name
      session[:briefcase] << asset.id
    else
      results[1] = asset.name
    end
    results
  end
  
  
  def remove
    unless params[:assets].nil?
      removed_assets = []
      assets =  params[:assets].uniq
      assets.each do |a|
        removed_assets << a unless session[:briefcase].delete(a.to_i).nil?
      end   
      flash[:notice] =""
      flash[:notice] << "Removed (#{removed_assets.size}) Assets.<br/>" unless removed_assets.empty? 
    else
      flash[:notice] = "You must select at least one file."
    end
    render_list
  end
  
  def remove_all
    session[:briefcase].clear
    flash[:notice] = "You emptied your briefcase"
    redirect_to :action=>'list'
  end
  
  #TODO: Create some sweeper event, which will remove zip files after a certain amount of time.
  def zip
      @zip_file = "#{RAILS_ROOT}/downloads/#{current_user.login}_briefcase_#{(Time.now).to_i}.zip"
    if create_zip(@zip_file)
      send_file @zip_file
    else
      render :text=>'error creating zip of briefcase'
    end
  end
  
  protected
  def render_list
    respond_to do |wants|
      wants.html do
        redirect_to :action=>'list'
      end
      wants.js do 
        render :update do |page|
          page.redirect_to :controller=>'briefcase',:action=>'list'
        #todo ajax removal
        end
      end
    end
  end
  
  def create_zip(path)
    Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zip|
      zip.dir.mkdir('briefcase') #acts as the root folder
      session[:briefcase].map do | a |
        asset = Asset.find a
        unless asset.nil?
          path = "briefcase/#{create_category_tree(asset.category_id)}"
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
