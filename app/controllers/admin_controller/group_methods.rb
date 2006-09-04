module AdminController::GroupMethods
  def groups
     @group_pages, @groups = paginate :groups, :per_page => 10
     render 'admin/groups'
   end
   
   def show_group
      @group       = Group.find_by_id_or_login(params[:id])
      #@non_members = @group.non_members.map{ |m| [m.login, m.id] }
      @non_members = @group.non_members
    end
    
    def update_group_memberships
      @group = Group.find(params[:id])
      if params[:group] && params[:group][:user_ids]
        @group = Group.find(params[:id])
        @existing_members = @group.members

        @members_from_params  = params[:group][:user_ids].map do |u| 
          user = User.find(u)
          user if user
        end
        #find the members to add and remove
        @members_to_add = @members_from_params - @existing_members
        @members_to_remove = @existing_members - @members_from_params
        
        #do the adding and deleting of memberships
        @members_to_add.each{|m| @group.users << m}
        @members_to_remove.each{|m| remove_a_member(@group,m)}
        
        @group.users(true) #reload
        
        flash[:notice] = "The group members have been modified. Added (#{@members_to_add.size}) and removed (#{@members_to_remove.size})"
      else
        #no members were returned in this form so implicitly they want to remove "everyone" from this group.
        remove_all_members(@group)
        flash[:notice] = "All Members of this group were removed."
      end if current_user.is_admin?
      redirect_to :back
    end

    def group_add_member
      @group       = Group.find_by_id_or_login(params[:id])
      @group.users << User.find(params[:user_id])
      @non_members = @group.non_members.map{ |m| [m.login, m.id] }

      render :update do |page|
        page.replace_html 'group_members',     :partial => 'group_members'
        page.replace_html 'available_members', :partial => 'add_group_member_dropdown'
        page.visual_effect :highlight, 'group_members'
      end
    end
    
    # For now it is probably best to keep the code DRY and only add groups within the cateory methods 
    # def add_group_to_category
    # 
    # end
    # 
    # def show_category_to_group_form
    #   @group = find_in_users_groups params[:group_id]
    #   render :update do |page|      
    #     unless @group.nil?
    #       @categories = current_user.categories
    #       page.replace_html 'add_group_to_category_form', :partial=>'group/category_form'
    #     else
    #       #they don't have access to this group
    #     end
    #   end
    # end
    
    def group_remove_member
      @group       = Group.find_by_id_or_login(params[:id])

      # Why the heck doesn't this work?!  This might be an ActiveRecord bug; I tried working with this in console and AR
      # *does* delete the record from its array cache, but the Membership remains in the DB. This doesn't seem right, so
      # I instead delete the Membership manually below.  It's the only way I found to truly get rid of the user from 
      # this group.
      #
      #@group.users.delete(User.find(params[:user_id]))

      Membership.find_by_user_id_and_collection_id(params[:user_id], @group.id).destroy
      @group.users(true) # Reload

      @non_members = @group.non_members.map{ |m| [m.login, m.id] }

      render :update do |page|
        page.replace_html 'group_members',     :partial => 'group_members'
        page.replace_html 'available_members', :partial => 'add_group_member_dropdown'
      end
    end
    
    def new_group
       @group = Group.new
       render 'group/new'
     end

     def create_group
         @group = Group.new(params[:group])
         if @group.save
           flash[:notice] = 'Group was successfully created.'
           redirect_to :action => 'groups'
         else
           render 'group/new'
         end
     end

     def edit_group
       unless params[:id].nil?
         @group = find_in_users_groups params[:id]
         render 'group/edit'
         render :text=>'Could not find this group in your account' if @group.nil?
       else
         flash[:notice] = "Cannot find group without an ID."
         redirect_to :action=>'groups'
       end
     end

     def update_group
       unless params[:id].nil?
         @group = find_in_users_groups params[:id]
         if @group.update_attributes(params[:group])
           flash[:notice] = 'Group was successfully updated.'
           redirect_to :action => 'group/show', :id => @group
         else
           render :action => 'group/edit'
         end
       else
         flash[:notice] = "Cannot find group without an ID."
         redirect_to :action=>'groups'
       end
     end

     def destroy_group
       unless params[:id].nil?
         @group = find_in_users_groups params[:id]
         @group.destroy unless @group.nil?
         redirect_to :action => 'groups'
        else
          flash[:notice] = "Cannot find group without an ID."
          redirect_to :action=>'groups'
        end
     end
     protected
     def remove_all_members(group)
       group.members.each do| m | 
         remove_a_member(group,m)
       end
     end
     def remove_a_member(group,member)
       membership = Membership.find_by_user_id_and_collection_id(member.id, group.id)
       membership.destroy if membership     
     end
end