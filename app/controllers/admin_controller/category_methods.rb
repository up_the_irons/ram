module AdminController::CategoryMethods
  
  #TODO this should be refactored and abstracted to a more generalized "edit_collection" method since group and category look nearly identical
  
  # def edit_category
  #   @category = Category.new
  #   @category = Category.find_by_id_or_name params[:id] if params[:id]
  #   if request.post? && @category
  #     params[:category][:user_id] = current_user.id if @category.new_record?
  #     
  #     #find the groups to add and remove from the category
  #     
  #     @potential_groups = []
  #     unless params[:category][:group_ids].nil?
  #       @potential_groups = params[:category][:group_ids] 
  #       params[:category].delete('group_ids')
  #     end
  #       
  #     #nest these calls inside a proc because adding elements to a new record without an ID will produce invalid joins
  #     add_groups = Proc.new do
  #       @added, @removed  = update_has_many_collection( @category,'groups', @potential_groups )
  #     end
  #       
  #     unless @category.new_record?
  #       add_groups.call
  #       add_groups = nil #delete the proc
  #     end  
  #     
  #     
  #     if @category.update_attributes(params[:category])
  #       add_groups.call unless add_groups.nil?
  #       
  #       flash[:notice] = "\"#{@category.name}\" was saved."
  #       flash[:notice] << "<br/>Added (#{@added.size}) groups and removed (#{@removed.size})" if defined?(@added) && defined?(@removed)
  #       redirect_to :action=>'edit_category', :id=>@category.id unless params[:id]  
  #       #TODO, redreaw the user's category tree which is kept in the session use a category observer for this 
  #     end
  #   end
  #   raise unless @category
  # rescue
  #   redirect_to :controller=>'admin', :action=>'categories'
  #   flash[:notice] = 'Could not find category.'
  # end
end