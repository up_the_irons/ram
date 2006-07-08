class ControllerTestGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions class_path, "#{class_name}ControllerTest"

      # Controller, helper, views, and test directories.
      m.directory File.join('test/functional', class_path)

      # Controller class, functional test, and helper class.
      m.template 'functional_test.rb',
                  File.join('test/functional',
                            class_path,
                            "#{file_name}_controller_test_stub.rb")
    end
  end
end
