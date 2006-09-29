class ChangeSweeper < ActionController::Caching::Sweeper
  observe Group, User, Category, Asset, Article
  
  def after_destroy(record)
    #return if controller.nil? 
    log(record, "DESTROY")
  end

  def after_update(record)
    #return if controller.nil?
    log(record, "UPDATE")
  end

  def after_create(record)
    #return if controller.nil?
    log(record, "CREATE")
  end

  def log(record, event, user = nil)
    user = controller.session[:user] unless controller.nil?
    Change.create(:record_id => record.id, :record_type => record.class.to_s, 
                      :event => event, :user_id => user)
  end
end
