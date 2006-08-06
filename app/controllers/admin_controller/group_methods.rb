module AdminController::GroupMethods
  def groups
     @group_pages, @groups = paginate :groups, :per_page => 10
     render 'admin/groups'
   end
   
   def show_group
      @group       = Group.find_by_id_or_login(params[:id])
      @non_members = @group.non_members.map{ |m| [m.login, m.id] }
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
end