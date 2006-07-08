class ModelTestGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions class_path, "#{class_name}Test"

      # Model, test, and fixture directories.
      m.directory File.join('test/unit', class_path)

      # Model class, unit test, and fixtures.
      m.template 'unit_test.rb',  File.join('test/unit', class_path, "#{file_name}_test_stub.rb")
    end
  end
end
