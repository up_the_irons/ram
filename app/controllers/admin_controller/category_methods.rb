module AdminController::CategoryMethods
  def categories
    @category_pages, @categories = paginate :categories, :per_page => 10
    render 'admin/categories'
  end
  
  def edit_category
    #@category = Category.find(params[:id])
    unless params[:id].nil?
      @category = find_in_users_categories(params[:id])
      render 'category/edit'
    else
      flash[:notice] = 'Cannot find category without an ID'
      redirect_to :action=>'categories'
    end
  end
  
  def add_group_to_category
    #breakpoint
     unless params[:group_id].nil?

       #@category = Category.find(params[:id])
       @category = find_in_users_categories(params[:id])
       g = Group.find(params[:group_id])
       @group = g if current_user.groups.include? g
       if @category.nil?
         flash[:notice] = 'Your do not have acces to this category.'
         render :update do |page|
             page.redirect_to :action=>'categories'
         end
       else
         unless @group.nil?
           @category.groups << @group
           @category.reload
           flash[:notice] = 'Your Group has been added'
           render :update do |page|
             page.replace_html(params[:update], :partial=>'category/new_group_button')
             page.replace_html('group_size', @category.groups.size)
             page.insert_html(  :bottom    , "group_list", :partial=>'category/group_item',:locals=>{:group=>@group,:category=>@category})
             page.visual_effect :highlight , "group_#{@group.id}", :duration=>1
             page.visual_effect :highlight , params[:update], :duration=>1
             page.replace_html('page_flash', flash[:notice] )
           end
         else
           #group could not be added because it does not belong to the user.
           flash[:notice] = "This group could not be located within your account."
           render :update do |page|
             page.replace_html('page_flash', flash[:notice] )
           end
         end
      end
     else
       #todo no group supplied display error or something.
     end 
   end

   def remove_group_from_category
     #todo scope this find to the user's categories
     @links = Linking.find_all_by_category_id_and_group_id(params[:id],params[:group_id])
     unless @links.empty?
       for l in @links
         # todo remove any assets in the presentation layer that depend on this linkage as well.
         l.destroy
       end
       #@category = Category.find(params[:id])
       @category = find_in_users_categories(params[:id])
       render :update do |page|
         page.replace_html('group_size', @category.groups.size)
         page.visual_effect :highlight , 'group_size', :duration=>1
         page.remove params[:update]
       end
     end
  end
   
  #TODO: This show method looks EXACTLY like the one in the category controller. Find some way to refactor them so that only one method is needed.
  def show_category
   respond_to do |wants|
     wants.html do
       #only show if this category appears inside the user's list of categories
       @category = find_in_users_categories(params[:id])
       
       @good_assets = []
       @groups = @category.groups & current_user.groups
       @assets = @category.assets
         
       @assets.each do |asset|
         @good_assets << asset unless (asset.groups & @groups).empty?
       end
       @assets = @good_assets
       render 'category/show'
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
  
  def new_category
    @category = Category.new
    render 'category/new'
  end

  def create_category
    case request.method
      when :get
        @category = Category.new
        render 'category/new'
      when :post
        @category = Category.create(params[:category])
  	    @category.user_id = current_user
  	    @category.save
        if @category.save
          flash[:notice] = 'Category was successfully created.'
          redirect_to :action => 'categories'
        else
          render 'category/new'
        end
    end
  end
  
  def destroy_category
    #Category.find(params[:id]).destroy
    find_in_users_categories(params[:id]).destroy
    redirect_to :action => 'categories'
  end
  
  def update_category
    #@category = Category.find(params[:id])
    @category = find_in_users_categories(params[:id])
    if @category.update_attributes(params[:category])
      flash[:notice] = 'Category was successfully updated.'
      #todo maybe do something fancy with this: request.parameters['controller'] so that it can be used in multiple controllers.
      if request.parameters['controller'] == 'admin'
        redirect_to :action => 'show_category', :id => @category
      else
        redirect_to :action => 'show', :id => @category
      end
    else
      render :action => 'category/edit'
    end
  end
  
end