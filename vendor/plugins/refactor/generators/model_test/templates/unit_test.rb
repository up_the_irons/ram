require File.dirname(__FILE__) + '/../test_helper'

class <%= class_name %>Test < Test::Unit::TestCase
  fixtures :<%= table_name %>
<% (class_name.constantize.public_methods - ActiveRecord::Base.public_methods).each do |m|
     method_name = m.to_s =~ /=$/ ? "set_#{m.to_s[0..-2]}" : m.to_s %>
  # Testing <%= class_name %>#<%= m %>
  def test_class_method_<%= method_name %>
    raise NotImplementedError
  end
<% end

class ActiveRecordBase < ActiveRecord::Base; def self.columns() []; end; end
   class_methods = class_name.constantize.new.public_methods
   ar_methods    = ActiveRecordBase.new.public_methods
   (class_methods - ar_methods).each do |m| 
     method_name = m.to_s =~ /=$/ ? "set_#{m.to_s[0..-2]}" : m.to_s %>
  # Testing <%= class_name.underscore %>#<%= m %>
  def test_instance_method_<%= method_name %>
    raise NotImplementedError
  end
<% end %>
end
