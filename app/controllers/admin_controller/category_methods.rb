module AdminController::CategoryMethods
  def categories
     @category_pages, @categories = paginate_collection current_user.categories, :page => @params[:page]
    #@category_pages, @categories = paginate :categories, :per_page => 10
    render 'admin/categories'
  end
  
  #TODO this should be refactored and abstracted to a more generalized "edit_collection" method since group and category look nearly identical
  def edit_category
    @category = Category.new
    @category = Category.find_by_id_or_name params[:id] if params[:id]
    if request.post? && @category
      params[:category][:user_id] = current_user.id if @category.new_record?
      
      #find the groups to add and remove from the category
      if params[:category][:group_ids]
        
        #nest these calls inside a proc because adding elements to a new record without an ID will produce invalid joins
        @potential_groups = params[:category][:group_ids]
        params[:category].delete('group_ids')
        add_groups = Proc.new do
          @added, @removed  = update_group_access( @category, @potential_groups )
        end
        
        unless @category.new_record?
          add_groups.call
          add_groups = nil #delete the proc
        end  
      end
      
      if @category.update_attributes(params[:category])
        add_groups.call unless add_groups.nil?
        
        flash[:notice] = "\"#{@category.name}\" was saved."
        flash[:notice] << "<br/>Added (#{@added.size}) groups and removed (#{@removed.size})" if defined?(@added) && defined?(@removed)
        redirect_to :action=>'edit_category', :id=>@category.id unless params[:id]  
        #TODO, redreaw the user's category tree which is kept in the session use a category observer for this 
      end
    end
    raise unless @category
  rescue
    redirect_to :controller=>'admin', :action=>'categories'
    flash[:notice] = 'Could not find category.'
  end
  
  #TODO: This looks nearly identical the group method (find a way to combine them)
  def destroy_category
    redirect_to :action=>'categories' and return unless request.post?
    begin
      find_in_users_categories(params[:id]).destroy
      flash[:notice] = "You Deleted the Category"
    rescue
      flash[:notice] = "Error Deleting Category"
    end
    redirect_to :action => 'categories'
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
  
protected
  def update_group_access(model,ids_to_keep_or_add = [])
    elements_to_add    = []
    elements_to_remove = []
    existing_elements = model.groups
    
    if ids_to_keep_or_add.empty?
      elements_to_remove = model.groups
      model.remove_all_groups #possibly refactor to take a param like model.remove_all :groups
      return [elements_to_add,existing_elements]
    end
      
    #todo is there a way to make this call all at once possibly using :conditions=>   
    elements_to_keep_or_add  = ids_to_keep_or_add.map do |u| 
      group = Group.find(u)
      group if group
    end
    
    #find the elements to add and remove
    elements_to_add  = elements_to_keep_or_add - existing_elements
    elements_to_remove = existing_elements - elements_to_keep_or_add
      
    #do the adding and deleting of elements
    elements_to_add.each{|m| model.groups << m}
    elements_to_remove.each{|m| model.remove_group(m)}
      
    model.groups(true) #reload
    
    [ elements_to_add, elements_to_remove]
  end
  
end