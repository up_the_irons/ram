task :find_unused_views => :environment do
  require 'application'

  controllers = {}
  Dir.glob('app/views/*/*.rhtml').each do |view|
    next if File.basename(view)[0..0] == '_' # skip partials
    
    ctrl_name = File.basename(File.dirname(view))
    unless controllers.key?(ctrl_name)
      begin
        ctrl = "#{ctrl_name.classify}Controller".constantize
        controllers[ctrl_name] = (ctrl.new.public_methods - ApplicationController.new.public_methods - ctrl.hidden_actions) \
                                   .collect { |a| a.to_s }
      rescue
        next
      end
    end
    
    puts view unless controllers[ctrl_name].include?(File.basename(view).split('.').first)
  end
end

