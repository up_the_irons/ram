ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

include AuthenticatedTestHelper
include RamTestHelper
include Arts

class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  # Add more helper methods to be used by all tests here...
  def login(name='user', password='super')
  	post:login, :user=>{:username=>name, :password=>password}
    assert_redirected_to :action =>'index'
    assert_not_nil(session[:user])
    user = User.find(session[:user].id)
    assert_equal 'super', user.username
  end
  
  # Needed by tests to simulate the use of this global variables in the application.
  $APPLICATION_SETTINGS = Setting.new({:application_name=>'RAM',:admin_group_id=>31,:filesize_limit=>55000})
  
  # Validates unique and required fields within the model.
  # NOTE: If you set a default value for a required attribute this test will not test the requirement because there
  # is already a value provided
  #call by declaring this in the unit_test: 
  # test_required_attributes Group, :user_id
  # test_unique_attributes Group, 1, :name
  # inital code based off: http://johnwilger.com/articles/2005/12/07/a-bit-of-dryness-for-unit-tests-in-rails
  class << self
    def test_required_attributes( klass, msg, *attributes )
      attributes.each do |attribute|
        self.class_eval do
          define_method("test_#{attribute}_is_required") do
            object = klass.new
            assert !object.valid?, "#{attribute} is not a valid #{klass} attribute"
            assert object.errors.on( attribute.to_sym ), "Expected errors on attribute '#{attribute}' for class '#{klass}' but there were none!"
            error_messages = object.errors.on( attribute.to_sym ).to_a
            assert error_messages.include?( msg ), "Expected: '#{msg}' on attribute '#{attribute}' for class '#{klass}'; but got #{error_messages} (Did you check your spelling genius?)."
          end
        end
      end
    end

    def test_unique_attributes( klass, msg, *attributes )
      attributes.each do |attribute|
        self.class_eval do
          define_method("test_#{attribute}_is_unique") do
            existing = klass.find(:first)
            object = klass.new
            object[attribute] = existing[attribute]
            assert !object.valid?, "#{attribute} is not a valid #{klass} attribute"
            assert object.errors.on( attribute.to_sym ), "Expected errors on attribute '#{attribute}' for class '#{klass}' but there were none!"
            error_messages = object.errors.on( attribute.to_sym ).to_a
            assert error_messages.include?( msg ), "Expected a specific error string on attribute '#{attribute}' for class '#{klass}', but it was not found (did you check your spelling genius?)."
          end
        end
      end
    end
    
    def test_numericality_attributes(klass, msg, *attributes)
      attributes.each do |attribute|
        self.class_eval do
          define_method("test_#{attribute}_is_numerical") do
            object = klass.new
            object[attribute] = "foo"
            assert !object.valid?, "#{attribute} is not a valid #{klass} attribute"
            assert object.errors.on( attribute.to_sym ), "Expected errors on attribute '#{attribute}' for class '#{klass}' but there were none!"
            error_messages = object.errors.on( attribute.to_sym ).to_a
            assert error_messages.include?( msg ), "Expected a specific error string on attribute '#{attribute}' for class '#{klass}', but it was not found (did you check your spelling genius?)."
          end
        end
      end
    end
    
  end

  # Stub method to loop through your class looking for methods to test.
  # This ensures that your application doesn't throw any obvious execeptions but is a rather shallow test.
  def self.test_actions(controller, options={})
    exclude = Set.new((options[:except] || []).to_a | [:wsdl, :rescue_action])
    controller_class = eval(Inflector.classify("#{controller}_controller"))
    controller_class.send(:action_methods).each do |method|
      define_method "test_#{method}" do
        unless exclude.include? method.to_sym
          assert_nothing_raised do
            get method
          end
        end
      end
    end
  end
  
  def assert_changed(object, method = nil)
    initial_value = object.send(method)
    yield
    assert initial_value != object.reload.send(method), "#{object}##{method} should not be equal"
  end

  def assert_unchanged(object, method, &block)
    initial_value = object.send(method)
    yield
    assert_equal initial_value, object.reload.send(method), "#{object}##{method} should be equal"
  end
  
  def uploaded_file(path, content_type="application/octet-stream", filename=nil)
    filename ||= File.basename(path)
    t = Tempfile.new(filename)
    FileUtils.copy_file(path, t.path)
    (class << t; self; end;).class_eval do
      alias local_path path
      define_method(:original_filename) { filename }
      define_method(:content_type) { content_type }
    end
    return t
  end
  
  # A JPEG helper
  def uploaded_jpeg(path, filename=nil)
    uploaded_file(path, 'image/jpeg', filename)
  end

  # A GIF helper
  def uploaded_gif(path, filename=nil)
    uploaded_file(path, 'image/gif', filename)
  end
end
