# TODO: It would be a good idea to allow the opts hash to take a string or a proc for keys like :on_success and :on_failure.
# providing this would allow you to do something more ellaborate than just display a status message.

module CollectionMethods
  
  def list_collection(opts={})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = {:table=>controller_name.pluralize, :many_associations=>[],:model=>Object.const_get(opts[:table].classify)}.merge(opts)
    
    #table = controller_name.pluralize unless table
    #model= Object.const_get(table.classify)
    pages, models = paginate_collection current_user.send(obj[:table].to_sym), :page => params[:page]
    instance_variable_set("@#{obj[:table].singularize}_pages", pages)
    instance_variable_set("@#{obj[:table]}", models)
    yield and return if block_given?
  end
  
  def changes(opts={})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = {:table=>controller_name.pluralize, :many_associations=>[],:model=>Object.const_get(opts[:table].classify)}.merge(opts)
    
    #table = controller_name.pluralize unless table
    #model= Object.const_get(table.classify)
    instance_variable_set("@#{obj[:table].singularize}", send("find_in_users_#{obj[:table]}", params[:id]))
    render :partial=>'shared/changes',:locals=>{:model=>instance_variable_get("@#{obj[:table].singularize}")},:layout=>'application'
  end
  
  def destroy_collection(opts={})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = {:table=>controller_name.pluralize, :many_associations=>[],:model=>Object.const_get(opts[:table].classify)}.merge(opts)
    
    #table = controller_name.pluralize unless table
    #model = Object.const_get(table.classify)
    instance_variable_set("@#{obj[:table].singularize}", send("find_in_users_#{obj[:table]}", params[:id]))

    yield and return if block_given?
    redirect_to :controller=>'inbox' and return unless request.post?
    instance_variable_get("@#{obj[:table].singularize}").destroy
    
    begin  
      flash[:notice] = opts[:on_success] || "You Deleted the #{obj[:model]}"
    rescue
      flash[:notice] = opts[:on_failure] || "Could not Delete #{obj[:model]}"
    end
    redirect_to :action=>obj[:table]
  end

  
  def show_collection(opts={})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = {:table=>controller_name.pluralize, :many_associations=>[],:model=>Object.const_get(opts[:table].classify)}.merge(opts)

    #table = controller_name.pluralize unless table
    #model = Object.const_get(table.classify)
    
    #find the object in the user's model for example current_user.categories etc.
    instance_variable_set("@#{obj[:table].singularize}", send("find_in_users_#{obj[:table]}", params[:id]))
    raise ActiveRecord::RecordNotFound unless instance_variable_get("@#{obj[:table].singularize}")
    yield and return if block_given?

    respond_to do |wants|
      wants.html do
        #not all collections will have contents
        send("#{obj[:table].singularize}_contents",params) if respond_to?("#{obj[:table].singularize}_contents")
        render "#{obj[:table].singularize}/show"
      end
      wants.js do 
        render :update do |page|
          page.redirect_to :action=>name.to_s ,:id=>params[:id]
        end
      end
    end
  rescue 
    flash[:notice] = "Could not find #{obj[:table].singularize}."  
    redirect_to( :controller=>'inbox') and return false
  end
  
  
  def edit_collection(opts={})
    obj = default_obj
    opts[:table] = controller_name.pluralize unless opts[:table]
    obj = {:table=>controller_name.pluralize, :many_associations=>[],:model=>Object.const_get(opts[:table].classify)}.merge(opts)
    #table = controller_name.pluralize unless table
    #model = Object.const_get(table.classify)
    #find the object in the user's model for example current_user.categories etc.
    instance_variable_set("@#{obj[:table].singularize}", obj[:model].send(:new))
    instance_variable_set("@#{obj[:table].singularize}", send("find_in_users_#{obj[:table]}", params[:id])) if params[:id]
    
    yield and return if block_given?  #thar be dragons past this point

    model_instance = instance_variable_get("@#{obj[:table].singularize}")
    model_sym = obj[:table].singularize.to_sym
    many_associations_results = ""
    #many_element = obj[:many_associations].singularize

    if request.post? && model_instance
      params[model_sym][:user_id] = current_user.id if model_instance.new_record?
      
      #save the record
      if model_instance.new_record?
        model_instance.attributes = params[model_sym]
        model_instance.save

        # Tags must be assigned after the object is saved b/c they rely on the ID of the record
        model_instance.tags = params[model_sym][:tags] if params[model_sym][:tags]
      end
      obj[:many_associations].each do| many_association |
        potential_elements = []
        added   = []
        removed = []
      
        many_association_sym = "#{many_association.singularize}_ids".to_sym
        unless params[model_sym][many_association_sym].nil?
          potential_elements = params[model_sym][many_association_sym] 
          params[model_sym].delete(many_association_sym)
        end

        #nest these calls inside a proc because adding elements to a new record without an ID will produce invalid joins
        #add_elements = Proc.new do
        added, removed  = update_has_many_collection( model_instance, many_association, potential_elements )
        many_associations_results << "<br/>Added (#{added.size}) #{many_association} and removed (#{removed.size})" if defined?(added) && defined?(removed)
        #end
        
        #unless model_instance.new_record?
        #  add_elements.call
        #  add_elements = nil #delete the proc
        #end  
      
      end
      
      #save a pre-existing record.
      if !model_instance.new_record? && model_instance.update_attributes(params[model_sym])
          #add_elements.call unless add_elements.nil?
          
      end
      
      #display results
      if model_instance.valid?
        flash[:notice] = "\"#{model_instance.name}\" was saved."
        flash[:notice] << many_associations_results
        redirect_to :action=>"edit_#{obj[:table].singularize}", :id=>model_instance.id unless params[:id]
      end
      
    end
    raise unless model_instance
  rescue
    redirect_to :controller=>'admin', :action=>obj[:table]
    flash[:notice] = "Could not find #{obj[:table].singularize}."
  end
  
  protected
  
  #helper method for has_many collection editing
  def update_has_many_collection(model, many_collection, ids_to_keep_or_add = [])
    many_klass = Object.const_get(many_collection.singularize.classify)
    elements_to_add    = []
    elements_to_remove = []
    existing_elements = model.send many_collection.to_sym
    
    if ids_to_keep_or_add.empty?
      elements_to_remove = model.send(many_collection)
      model.send "remove_all_#{many_collection}".to_sym
      model.reload
      return [elements_to_add,existing_elements]
    end
      
    #todo is there a way to make this call all at once possibly using :conditions=>   
    elements_to_keep_or_add  = ids_to_keep_or_add.map do |u| 
      element = many_klass.find(u)
      element if element
    end
    
    #find the elements to add and remove
    elements_to_add  = elements_to_keep_or_add - existing_elements
    elements_to_remove = existing_elements - elements_to_keep_or_add
      
    #do the adding and deleting of elements
    elements_to_add.each{|m| model.send(many_collection.to_sym) << m}
    elements_to_remove.each{|m| model.send "remove_#{many_collection.singularize}".to_sym ,m }
      
    model.reload
    
    [ elements_to_add, elements_to_remove]
  end
  
   
  def default_obj
    {:table=>nil, :on_success=>nil, :on_failure=>nil}
  end
  
end
