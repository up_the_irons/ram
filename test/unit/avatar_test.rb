require File.dirname(__FILE__) + '/../test_helper'

class AvatarTest < Test::Unit::TestCase
  fixtures :users, :avatars

  def test_create_avatar
    assert_difference Avatar, :count do
      assert an_avatar
    end
  end
  
  def test_destroy_avatar
    a = an_avatar
    assert_difference Avatar, :count, -1 do
      a.destroy
    end
  end
end
