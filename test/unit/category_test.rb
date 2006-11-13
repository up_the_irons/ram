require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_unit_helper'

class CategoryTest < Test::Unit::TestCase
  fixtures :collections, :memberships, :users, :linkings

  def setup
    @model = Category
    @record_one = Category.find(6)
    @new_obj = {
      :name => 'Press',
      :description => 'News clippings from around the world',
      :state_id => 1,
      :public => true,
      :user_id => 1
    }
  end
  
  def test_create_category
    unit_create @model,@new_obj 
  end
  
  def test_category_children_shall_not_use_identical_names
    c= @model.find(:first)
    s = c.children.size
    nc = @model.create(:name=>c.name, :parent_id=>c.parent_id)
    assert nc.errors.on(:name)
  end
  
  def category_cannot_specify_self_as_parent
    c = @model.find(15)
    c.parent_id = c.id
    assert_equal c.save, false
    
    c.parent_id = nil
    assert c.save
  end
  
  def test_destroy_category
    @model.destroy(6)
    assert_raise(ActiveRecord::RecordNotFound) {@model.find(6)}
  end
  
  def test_update_category
    @id = @model.find(:first).id
    @new_values = {
      :name=> 'Contact',
      :description=>'Feel free to send us chocolates'
    }
    assert_changed @model.find(@id), :updated_at do
      unit_update @model, @id, @new_values
    end
  end
  
  def test_category_shall_act_as_tree
    assert_equal 4, Category.find(6).children.size
    assert_equal Category.find(8).parent, Category.find(6)
  end
  
  def test_category_shall_not_allow_duplicate_children
    c = @model.find(6)
    s = c.children.size
  
    c.children << c.children[0]

    assert c.save
    assert_equal s,  @model.find(c.id).children.size
  end
  
  def test_category_shall_not_allow_duplicate_groups
    c = @model.find(6)
    s = c.groups.size
    c.groups << c.groups[0]
    assert c.save
    assert_equal s,  @model.find(c.id).groups.size
  end
  
  def test_destroying_category_nullifies_associated_linkings_but_does_not_delete_them

  end
 
end
