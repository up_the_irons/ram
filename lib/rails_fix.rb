# See http://dev.rubyonrails.org/ticket/5279

module Rails
  class Initializer
    def process
      check_ruby_version
      set_load_path
      set_connection_adapters

      require_frameworks
      load_environment

      initialize_database
      initialize_logger
      initialize_framework_logging
      initialize_framework_views
      initialize_dependency_mechanism
      initialize_breakpoints
      initialize_whiny_nils
      initialize_temporary_directories

      load_plugins

      initialize_framework_settings
      
      # Support for legacy configuration style where the environment
      # could overwrite anything set from the defaults/global through
      # the individual base class configurations.
      load_environment
      
      add_support_load_paths

      # Routing must be initialized after plugins to allow the former to extend the routes
      initialize_routing
      
      # the framework is now fully initialized
      after_initialize
    end
  end
end
