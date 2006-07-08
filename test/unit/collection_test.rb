require File.dirname(__FILE__) + '/../test_helper'

class CollectionTest < Test::Unit::TestCase
  fixtures :collections

  # Replace this with your real tests.
  def test_state
    c = Collection.new(:state_id => 2)
    assert_equal 'Approved', c.state
  end
end
