# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.1.6'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Back-ported Rails fixes
require File.join(File.dirname(__FILE__), '../lib/rails_fix')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :user_observer, :group_observer
  #
  # I commented out the above line b/c of this bug:
  # http://rails.techno-weenie.net/question/2006/4/25/plugins_arent_being_loaded
  #
  # This ticket fixes the problem but is not in stable yet:
  # http://dev.rubyonrails.org/ticket/5279
  #
  # However, only GroupObserver is affected by this, and not including 
  # user_observer is throwing a test failure (I don't really know why the group
  # one can be loaded in the controller but the user one must be loaded here)
  config.active_record.observers = :user_observer

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
require 'openssl'
require 'base64'
require 'ostruct'

# OpenStruct is used in several places throughout the app to fake out views, which are expecting AR models.
# To prevent the tests and application from whining about Object#id we undefine it here so that we can override it 
# later.
OpenStruct.class_eval { undef :id }

UPLOAD_SIZE_LIMIT = 50000 * 1024
RAM_SALT          = 'foodz'

begin
  @setting = Setting.find(:first)
  @setting.preferences = { :rmagick => true } unless @setting.preferences || @setting.preferences.empty?
  $APPLICATION_SETTINGS = @setting
rescue
  @setting = OpenStruct.new({:application_name => 'RAM',:admin_group_id => 1,:filesize_limit => 55000, :preferences => {:rmagick => true}})
  $APPLICATION_SETTINGS = @setting
end

begin
  require 'RMagick'
  unless @setting.preferences[:rmagick]
    @setting.preferences[:rmagick] = true
    @setting.save!
    $APPLICATION_SETTINGS = @setting
  end
rescue LoadError
  # Failed to load RMagick
  $APPLICATION_SETTINGS.preferences[:rmagick] = false
end

begin
  # Codename generated from the dictionary
  @rev = YAML.load(`svn info`)['Revision'] if File.exist?('.svn')
  @codename  = IO.readlines("/usr/share/dict/words")[@rev]
rescue
  @rev = ""
  @codename = ""
end

REVISION_NUMBER = @rev
APP_CODENAME = @codename

$KCODE = 'UTF8'
