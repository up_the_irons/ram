ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'pp'
class Test::Unit::TestCase

  def unit_create(model,options)
    pre_count = model.count
    @o = model.new(options)
    assert @o.save
    assert_equal pre_count + 1, model.count
    assert_kind_of model, @o
  end
  
  def unit_destroy(model,id)
    pre_count = model.count
    @o = model.find(id)
    assert @o.destroy
	assert_equal pre_count - 1, model.count
	
    assert_raise(ActiveRecord::RecordNotFound) { model.find(id) }
  end
  
  def unit_update(model,id,value_hash)
    assert @o = model.find(id), "cannot test update because record was not found"
    value_hash.each do |key,value|
      @o[key] = value
    end
    assert @o.save, "could not update object, failed to save"
    @o.reload
    value_hash.each do |key,value|
      assert_equal @o[key], value, "after update the database does not contain the new values."
    end
  end
  
  def unit_protect_update_against_duplicate_records(original_record,record_to_update,*attributes)
    attributes.each do |attribute|
      record_to_update[attribute] = original_record [attribute]
    end
    assert !record_to_update.save, "the application updated the record even though it contained duplicate information on unique fields"
    attributes.each do |attribute|
      assert record_to_update.errors.on( attribute), "the application should have contained an error on field '#{attribute}'"
    end
  end
  
end
