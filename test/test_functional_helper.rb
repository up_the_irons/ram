ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
class Test::Unit::TestCase
  
  class << self
  
  	#expects a format like this:
	#test_required_attributes_in_controller User,
  	#										{:params=>{:id=>1,:user=>{}},:session=>{:user=>{}}},
	#										[:create, :update],
	#										:first_name, :last_name, :username, :email_address, :password

    def test_required_attributes_in_controller( model, options, actions,*required_fields )
    	
		sym = model.to_s.downcase.to_sym
		for field in required_fields
      		options[:params][sym][field] = ''
    	end
		
      	actions.each do |action|
        	self.class_eval do
          		define_method("test_#{action}_method_requires_fields") do
            		assert_nothing_raised do
						post action, options[:params],options[:session]
					end
            		for field in required_fields
      					assert !assigns(sym).errors[field].empty? unless options[:params][sym][field] == ''
    				end
    				assert !assigns.empty?,"This method requires specific parameters, yet no errors were created with them missing"
          		end
        	end
      	end
	end
	
	  #Expects format like this: 
	  #   test_required_unique_attributes_in_controller User,
	  #											{:params=>{:id=>1,:user=>{}},:session=>{:user=>{}}},
	  #											[:create, :update],
	  #											:username, :email_address
	  #
		
    def test_required_unique_attributes_in_controller( model, options, actions,*required_fields )
    	sym = model.to_s.downcase.to_sym
		for field in required_fields
      		options[:params][sym][field] = ''
    	end
		
      	actions.each do |action|
        	self.class_eval do
          		define_method("test_#{action}_method_requires_unique_fields") do
            		assert_nothing_raised do
						post action, options[:params],options[:session]
					end
            		for field in required_fields
      					assert !assigns(sym).errors[field].empty? unless options[:params][sym][field] == ''
    				end
    				assert !assigns.empty?,"This method fails without unique parameters, yet no errors were created"
          		end
        	end
      	end
    end
	
	#Expects format like this:
	# test_required_url_parameters_in_controller 
	#                                           User,
	#                                                {:params=>{},:session=>{:user=>{}}},
	#                                                :edit, :destroy, :show, :update	
	
    def test_required_url_parameters_in_controller(model, options, *actions)
      sym = model.to_s.downcase.to_sym
      actions.each do |action|
        self.class_eval do
          define_method("test_#{action}_method_requires_url_parameters") do
            post action, options[:params],options[:session]
            assert_response :redirect
            assert_nil assigns(sym),"This method requires a url parameter, yet the controller still created an object."
          end
        end
      end
    end
	
  end
  
  def functional_verify_redirection_on_get(action,redirect,options={},session={})
    get action,options,session
    assert_redirected_to :action=>redirect
  end
  
  def functional_verify_get(action,options={},session={})
    get action,options,session
    assert_response :success
  end
  
  def functional_show(model,options={:params=>{:id=>1},:session=>{}})
    sym = model.to_s.downcase.to_sym
    get :show, options[:params], options[:session]
    assert_response :success
    assert_not_nil assigns(sym)
    assert assigns(sym).valid?
  end
  
  def functional_assert_id_errors(action,model,options={:params=>{:id=>''},:session=>{}},required_fields=[])
    sym = model.to_s.downcase.to_sym
    post action, options[:params],options[:session]
    assert_response :redirect
  end
  
  def functional_assert_parameter_errors(action,model,options={:params=>{:id=>1},:session=>{}},required_fields=[])
    sym = model.to_s.downcase.to_sym
    assert_nothing_raised do
      post action, options[:params],options[:session]
    end
    for field in required_fields
      assert !assigns(sym).errors[field].empty? unless options[:params][sym][field] == ''
    end
    
    assert !assigns.empty?
  end
  
  def functional_index(options={:params=>{},:session=>{}})
     get :index, options[:params], options[:session]
     assert_response :success
     assert_template 'list'
  end

  def functional_list(model,options={:params=>{},:session=>{}})
    sym = model.to_s.downcase.pluralize.to_sym
    get :list,options[:params],options[:session]
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(sym)
  end

  def functional_new(model,options={:params=>{},:session=>{}})
    sym = model.to_s.downcase.to_sym
    get :new, options[:params], options[:session]
    assert_response :success
    assert_template 'new'
    assert_kind_of model, assigns(sym)
  end

  def functional_create(model,options={:params=>{},:session=>{}})
    sym = model.to_s.downcase.to_sym
    pre_count = model.count
    post :create, options[:params], options[:session]
    assert_response :redirect
    assert_equal pre_count + 1, model.count
    assert_equal 0, assigns(sym).errors.count
    assert_kind_of model, model.find(assigns(sym).id)
  end

  def functional_edit(model,options={:params=>{},:session=>{}})
    get :edit, options[:params], options[:session]
    assert flash.empty?
    assert_response :success
    assert_not_nil assigns[model.to_s.downcase]
    assert_template 'edit'
  end

  def functional_update(model,options={:params=>{},:session=>{}})
    sym = model.to_s.downcase.to_sym
    post :update, options[:params], options[:session]
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => options[:params][:id]
    assert_equal 0, assigns(sym).errors.count
    assert_kind_of model, model.find(assigns(sym).id)
  end

  def functional_destroy(model,options={:params=>{},:session=>{}})
    assert_not_nil model.find(options[:params][:id])
    post :destroy, options[:params], options[:session]
    assert_response :redirect
    assert_raise(ActiveRecord::RecordNotFound) { model.find(options[:params][:id]) }
  end
end
