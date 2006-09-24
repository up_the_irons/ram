# TODO: It would be a good idea to allow the opts hash to take a string or a proc for keys like :on_success and :on_failure.
# providing this would allow you to do something more ellaborate than just display a status message.

module CollectionMethods
  
  def list_collection(table=nil,opts={:on_success=>nil,:on_failure=>nil})
    table = controller_name.pluralize unless table
    model= Object.const_get(table.classify)
    pages, models = paginate_collection current_user.send(table.to_sym), :page => params[:page]
    instance_variable_set("@#{table.singularize}_pages", pages)
    instance_variable_set("@#{table}", models)
    yield and return if block_given?
  end
  
  def destroy_collection(table=nil,opts={:on_success=>nil,:on_failure=>nil})
    table = controller_name.pluralize unless table
    model = Object.const_get(table.classify)
    instance_variable_set("@#{table.singularize}", send("find_in_users_#{table}", params[:id]))

    yield and return if block_given?
    redirect_to :controller=>'inbox' and return unless request.post?
    instance_variable_get("@#{table.singularize}").destroy
    
    begin  
      flash[:notice] = opts[:on_success] || "You Deleted the #{model}"
    rescue
      flash[:notice] = opts[:on_failure] || "Could not Delete #{model}"
    end
    redirect_to :action=>table
  end

  
  def show_collection(table=nil,opts={:on_success=>nil,:on_failure=>nil})
    table = controller_name.pluralize unless table
    model = Object.const_get(table.classify)
    #find the object in the user's model for example current_user.categories etc.
    instance_variable_set("@#{table.singularize}", send("find_in_users_#{table}", params[:id]))
    raise ActiveRecord::RecordNotFound unless instance_variable_get("@#{table.singularize}")
    yield and return if block_given?

    respond_to do |wants|
      wants.html do
        #not all collections will have contents
        send("#{table.singularize}_contents",params) if respond_to?("#{table.singularize}_contents")
        render "#{table.singularize}/show"
      end
      wants.js do 
        render :update do |page|
          page.redirect_to :action=>name.to_s ,:id=>params[:id]
        end
      end
    end
  rescue 
    flash[:notice] = "Could not find #{table.singularize}."  
    redirect_to( :controller=>'inbox') and return false
  end
  
  def edit_collection(table=nil, many_elements=nil, opts={:on_success=>nil,:on_failure=>nil})
    table = controller_name.pluralize unless table
    model = Object.const_get(table.classify)
    #find the object in the user's model for example current_user.categories etc.
    instance_variable_set("@#{table.singularize}", model.send(:new))
    instance_variable_set("@#{table.singularize}", send("find_in_users_#{table}", params[:id])) if params[:id]
    
    yield and return if block_given?  #thar be dragons past this point

    model_instance = instance_variable_get("@#{table.singularize}")
    model_sym = table.singularize.to_sym
    many_element = many_elements.singularize
    if request.post? && model_instance
      params[model_sym][:user_id] = current_user.id if model_instance.new_record?
      
      #find the groups to add and remove from the category
      
      @potential_elements = []
      unless params[model_sym]["#{many_element}_ids".to_sym].nil?
        @potential_elements = params[model_sym]["#{many_element}_ids".to_sym] 
        params[model_sym].delete("#{many_element}_ids")
      end
        
      #nest these calls inside a proc because adding elements to a new record without an ID will produce invalid joins
      add_elements = Proc.new do
        @added, @removed  = update_has_many_collection( model_instance, many_elements, @potential_elements )
      end
        
      unless model_instance.new_record?
        add_elements.call
        add_elements = nil #delete the proc
      end  
      
      
      if model_instance.update_attributes(params[model_sym])
        add_elements.call unless add_elements.nil?
        
        flash[:notice] = "\"#{model_instance.name}\" was saved."
        flash[:notice] << "<br/>Added (#{@added.size}) groups and removed (#{@removed.size})" if defined?(@added) && defined?(@removed)
        redirect_to :action=>"edit_#{table.singularize}", :id=>model_instance.id unless params[:id]  
      end
    end
    raise unless model_instance
  rescue
    redirect_to :controller=>'admin', :action=>table
    flash[:notice] = "Could not find #{table.singularize}."
  end
  
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
  
end