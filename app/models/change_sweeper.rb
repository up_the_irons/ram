class ChangeSweeper < ActionController::Caching::Sweeper
  observe Group, User, Category, Asset, Article
  
  def after_destroy(record)
    #return if controller.nil? 
    log(record, "DESTROY")
    log_for_child(record,"Removed #{record.name}")
  end


  def after_update(record)
    #return if controller.nil?
    log(record, "UPDATE")
  end


  def after_create(record)
    #return if controller.nil?
    log(record, "CREATE")
    log_for_child(record,"Added #{record.name}")    
  end
  
  protected
  
  def log_for_child(record, event, user= nil)
    case record.class.to_s
      when 'Asset','Article':
        log( Category.find(record.category_id) , event) unless record.category_id.nil?
      when 'Category':
        log(Category.find(record.parent_id), event) unless record.parent_id.nil?
    end
  end
  
  
  def log(record, event, user= nil)
    user = controller.session[:user] unless controller.nil?
    Change.create(:record_id => record.id, :record_type => record.class.to_s, 
                      :event => event, :user_id => user)
  end
  
end
