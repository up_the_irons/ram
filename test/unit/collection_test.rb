require File.dirname(__FILE__) + '/../test_helper'

class CollectionTest < Test::Unit::TestCase
  fixtures :collections, :settings

  def test_state
    c = Collection.new(:state_id => 2)
    assert_equal 'Approved', c.state
  end
end
