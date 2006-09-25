module AdminController::GroupMethods
    
  #this method replaces create, update, new and edit
  # def edit_group
  #   @group = Group.new
  #   @group = Group.find_by_id_or_name params[:id] if params[:id]
  #   if request.post? && @group
  #     params[:group][:user_id] = current_user.id if @group.new_record?
  #     
  #     @potential_members = []
  #     unless params[:group][:user_ids].nil?
  #       @potential_members = params[:group][:user_ids] 
  #       params[:group].delete('user_ids')
  #     end
  #       
  #     #nest these calls inside a proc because adding members to a new record without an ID will produce invalid memberships        
  #     add_members = Proc.new do
  #       @added, @removed  = update_has_many_collection( @group, 'users', @potential_members )
  #     end
  #       
  #     unless @group.new_record?
  #       add_members.call
  #       add_members = nil
  #     end  
  #     
  #     if @group.update_attributes(params[:group])
  #       add_members.call unless add_members.nil?
  #       
  #       flash[:notice] = "\"#{@group.name}\" was saved."
  #       flash[:notice] << "<br/>Added (#{@added.size}) members and removed (#{@removed.size})" if defined?(@added) && defined?(@removed)
  #       redirect_to :action=>'edit_group', :id=>@group.id unless params[:id] 
  #     end
  #     
  #   end
  # rescue
  #   flash[:notice] = 'Could not find group.'
  # end
end
