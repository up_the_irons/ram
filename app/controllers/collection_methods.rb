#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

# TODO: It would be a good idea to allow the opts hash to take a string or a proc for keys like :on_success and :on_failure.
# providing this would allow you to do something more ellaborate than just display a status message.

module CollectionMethods
  
  def list_collection(opts = {})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = { :table => controller_name.pluralize, :many_associations => [], :model => Object.const_get(opts[:table].classify) }.merge(opts)
    
    pages, models = paginate_collection current_user.send(obj[:table].to_sym), :page => params[:page], :per_page => params[:num_per_page]
    instance_variable_set("@#{obj[:table].singularize}_pages", pages)
    instance_variable_set("@#{obj[:table]}", models)
    yield and return if block_given?
  end
  
  def changes(opts = {})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = { :table => controller_name.pluralize, :many_associations => [], :model => Object.const_get(opts[:table].classify) }.merge(opts)
    instance_variable_set("@#{obj[:table].singularize}", send("find_in_users_#{obj[:table]}", params[:id]))
    
    render :partial => 'shared/changes', :locals => { :model => instance_variable_get("@#{obj[:table].singularize}") }, :layout=>'application'
  end
  
  def destroy_collection(opts = {})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = { :table => controller_name.pluralize, :many_associations => [], :model => Object.const_get(opts[:table].classify) }.merge(opts)
    instance_variable_set("@#{obj[:table].singularize}", send("find_in_users_#{obj[:table]}", params[:id]))
    
    yield and return if block_given?
    
    redirect_to :controller => 'inbox' and return unless request.post?
    instance_variable_get("@#{obj[:table].singularize}").destroy
    
    # Refresh category tree if any group has modified collection memberships
    session[:category_tree] = current_user.categories_as_tree(true) if opts[:table] == 'groups'

    begin  
      flash[:notice] = opts[:on_success] || "You Deleted the #{obj[:model]}"
    rescue
      flash[:notice] = opts[:on_failure] || "Could not Delete #{obj[:model]}"
    end
    redirect_to :action => obj[:table]
  end

  def show_collection(opts = {})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = { :table => controller_name.pluralize, :many_associations => [], :model => Object.const_get(opts[:table].classify) }.merge(opts)
    
    # Find the object in the user's model for example current_user.categories etc.
    instance_variable_set("@#{obj[:table].singularize}", send("find_in_users_#{obj[:table]}", params[:id]))
    raise ActiveRecord::RecordNotFound unless instance_variable_get("@#{obj[:table].singularize}")
    yield and return if block_given?

    respond_to do |wants|
      wants.html do
        # Not all collections will have contents
        send("#{obj[:table].singularize}_contents",params) if respond_to?("#{obj[:table].singularize}_contents")
        render "#{obj[:table].singularize}/show"
      end
      wants.js do 
        render :update do |page|
          page.redirect_to :action=>name.to_s, :id=>params[:id]
        end
      end
    end
  rescue 
    flash[:notice] = "Could not find #{obj[:table].singularize}."  
    redirect_to(:controller => 'inbox') and return false
  end
  
  def edit_collection(opts = {})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = { :table => controller_name.pluralize, :many_associations => [], :model => Object.const_get(opts[:table].classify) }.merge(opts)
    
    # Find the object in the user's model for example current_user.categories etc.
    instance_variable_set("@#{obj[:table].singularize}", obj[:model].send(:new))
    instance_variable_set("@#{obj[:table].singularize}", send("find_in_users_#{obj[:table]}", params[:id])) if params[:id]
    
    model_instance = instance_variable_get("@#{obj[:table].singularize}")
    raise and return unless model_instance # The view will produce an error without instance variable
    yield and return if block_given?  # Thar be dragons past this point!
    
    model_sym = obj[:table].singularize.to_sym
    many_associations_results = ""

    return unless request.post? && model_instance
    
    params[model_sym][:user_id] = current_user.id if model_instance.new_record?
      
    # Save the record and strip out the has_many associations so that the record saves correctly.
    # TODO: Find a way to make this more succient. 
    attributes = params[model_sym].dup
    obj[:many_associations].each do | m | 
      attributes.delete("#{m.singularize}_ids".to_sym)
      attributes.delete("tags") if params[model_sym][:tags]
    end
    model_instance.attributes = attributes
    model_instance.save

    # Tags must be assigned after the object is saved b/c they rely on the ID of the record
    model_instance.tags = params[model_sym][:tags] if params[model_sym][:tags]
      
    obj[:many_associations].each do |many_association|
      potential_elements = []
      added   = []
      removed = []
      
      many_association_sym = "#{many_association.singularize}_ids".to_sym
      unless params[model_sym][many_association_sym].nil?
        potential_elements = params[model_sym][many_association_sym] 
        params[model_sym].delete(many_association_sym)
      end

      # Nest these calls inside a proc because adding elements to a new record without an ID will produce invalid joins
      added, removed = update_has_many_collection(model_instance, many_association, potential_elements)

      # Refresh category tree if any group has modified collection memberships
      if model_instance.class == Group && (added.size > 0 || removed.size > 0) 
        session[:category_tree] = current_user.categories_as_tree(true)
      end

      many_associations_results << "<br/>Added (#{added.size}) #{many_association} and removed (#{removed.size})" if defined?(added) && defined?(removed)  

      # Display results
      if model_instance.valid?
        flash[:notice] = "\"#{model_instance.name}\" was saved."
        flash[:notice] << many_associations_results
        redirect_to(:action => "edit_#{obj[:table].singularize}", :id => model_instance.id) and return false unless params[:id]
      else
        flash[:notice] = "The #{model_instance.class.class_name} could not be saved."
      end
    end

  rescue
    unless RAILS_ENV == 'development' 
      redirect_to :controller => 'admin', :action => obj[:table]
      flash[:notice] = "Could not find #{obj[:table].singularize}."
    else
      raise
    end
  end
  
  protected
  
  # Helper method for has_many collection editing
  def update_has_many_collection(model, many_collection, ids_to_keep_or_add = [])
    many_klass = Object.const_get(many_collection.singularize.classify)
    elements_to_add    = []
    elements_to_remove = []
    existing_elements = model.send many_collection.to_sym
    
    if ids_to_keep_or_add.empty?
      elements_to_remove = model.send(many_collection)
      model.send "remove_all_#{many_collection}".to_sym
      model.reload
      return [elements_to_add, existing_elements]
    end
      
    # TODO: Is there a way to make this call all at once possibly using :conditions=>  ? 
    elements_to_keep_or_add = ids_to_keep_or_add.map do |u| 
      element = many_klass.find(u)
      element if element
    end
    
    # Find the elements to add and remove
    elements_to_add    = elements_to_keep_or_add - existing_elements
    elements_to_remove = existing_elements - elements_to_keep_or_add
      
    # Do the adding and deleting of elements
    elements_to_add.each { |m| model.send(many_collection.to_sym) << m }
    elements_to_remove.each { |m| model.send "remove_#{many_collection.singularize}".to_sym, m }
      
    model.reload
    
    [elements_to_add, elements_to_remove]
  end
  
  def default_obj
    { :table => nil, :on_success => nil, :on_failure => nil }
  end
  
end
