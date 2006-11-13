require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_unit_helper'

class LinkingTest < Test::Unit::TestCase
  fixtures :attachments, :collections, :linkings

  def setup
    @model = Linking
    @record_one = Linking.find(1)
    @new_obj = {
      :group_id=>1, 
      :category_id=>1, 
      :user_id=>1, 
      :linkable_type=>'Asset', 
      :linkable_id=>1
    }
  end
  
  def test_create_linking
    unit_create @model,@new_obj 
  end
  
  def test_destroy_linking
    unit_destroy @model
  end
  
  def test_destroy_linking
    unit_destroy @model, @model.find(:first).id
  end
  
  def test_update_linking
    @id = @model.find(:first).id
    @new_values = {
      :group_id=>2, 
      :category_id=>2, 
      :user_id=>1, 
      :linkable_type=>'Asset', 
      :linkable_id=>1
    }
    unit_update @model, @id, @new_values
  end

  def test_linkings_shall_look_for_partial_records_to_complete_before_creating_new_partials
    # TODO
  end

end
