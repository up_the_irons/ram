class CategoryController < ProtectedController
  layout "application", :except => [:feed]
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
       category_contents(params)
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
    category_contents(params)
  end
    
protected
  def category_contents(params)
    params[:display] = 'all' if params[:display].nil?
    @category = find_in_users_categories(params[:id])
    @groups   = @category.groups & current_user.groups
    case params[:display]
      when 'assets'
        @assets = find_assets(@category,@groups)
      when 'articles'
        @articles = find_articles(@category)
      else
      #find all
      @assets   = find_assets(@category,@groups)
      @articles = find_articles(@category)
    end
  end 
  
  def find_assets(category,groups)
    good_assets = []
    assets = category.assets
    assets.each do |asset|
      good_assets << asset unless (asset.groups & groups).empty?
    end
    good_assets
  end
  
  def find_articles(category)
    category.articles  #TODO: This needs to be scoped to a group in the same way assets are.
  end

end
