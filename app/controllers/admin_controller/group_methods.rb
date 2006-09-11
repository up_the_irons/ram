module AdminController::GroupMethods
  def groups
     @group_pages, @groups = paginate :groups, :per_page => 10
     render 'admin/groups'
   end
   
  def show_group
      @group       = Group.find_by_id_or_login(params[:id])
      render 'group/show'
  rescue
    redirect_to :controller=>'admin', :action=>'groups'
    flash[:notice] = 'Could not find group.'  
  end
    
  #this method replaces create, update, new and edit
  def edit_group
    @group = Group.new
    @group = find_group_by params[:id] if params[:id]
    if request.post? && @group
      params[:group][:user_id] = current_user.id if @group.new_record?
      
      #find the users to add and remove from the group
      if params[:group][:user_ids]
        
        #nest these calls inside a proc because adding members to a new record without an ID will produce invalid memberships
        @potential_members = params[:group][:user_ids]
        params[:group].delete('user_ids')
        add_members = Proc.new do
          @added, @removed  = update_group_memberships( @group, @potential_members )
        end
        
        unless @group.new_record?
          add_members.call
          add_members = nil
        end  
      end
      
      if @group.update_attributes(params[:group])
        add_members.call unless add_members.nil?
        
        flash[:notice] = "\"#{@group.name}\" was saved."
        flash[:notice] << "<br/>Added (#{@added.size}) members and removed (#{@removed.size})" if defined?(@added) && defined?(@removed)
      end
      redirect_to :action=>'edit_group', :id=>@group.id unless params[:id]  
    end
  rescue
    flash[:notice] = 'Could not find group.'
  end
  
  #A group is not destroyed its disbanded!
  def disband_group
    redirect_to :action=>'groups' and return unless request.post?
    @group = find_group_by params[:id]
    @group.destroy
    flash[:notice] = "You disbanded the group."
    redirect_to :action => 'groups'
  rescue
    flash[:notice] = "Could not find group."
    redirect_to :action=>'groups'
  end
     
  protected
  def update_group_memberships(group,user_ids = [])
    members_to_add    = []
    members_to_remove = []
    existing_members = group.members
    
    if user_ids.empty?
      #no members were returned in this form so implicitly they want to remove "everyone" from this group.
      members_to_remove = group.members
      remove_all_members(group)
      return [members_to_add,existing_members]
    end
      
    members_from_params  = user_ids.map do |u| 
      user = User.find(u)
      user if user
    end
    
    #find the members to add and remove
    members_to_add    = members_from_params - existing_members
    members_to_remove = existing_members    - members_from_params
      
    #do the adding and deleting of memberships
    members_to_add.each{|m| group.users << m}
    members_to_remove.each{|m| remove_a_member(group,m)}
      
    group.users(true) #reload
    
    [ members_to_add, members_to_remove]
  end
  
  def remove_all_members(group)
    group.members.each do| m | 
      remove_a_member(group,m)
    end
  end
     
  def remove_a_member(group,member)
    membership = Membership.find_by_user_id_and_collection_id(member.id, group.id)
    membership.destroy if membership     
  end
     
  def find_group_by(param)
    if params[:id].to_s.match(/^\d+$/)
      group = Group.find(param)
    else
      group = Group.find_by_name(param)
    end
  end
  
end