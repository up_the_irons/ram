#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  created_on          :datetime      
#  updated_on          :datetime      
#  bio                 :text          
#  address_line1       :string(255)   default()
#  address_line2       :string(255)   default()
#  city                :string(255)   default()
#  state               :string(255)   default()
#  country             :string(255)   default()
#  postal_code         :string(255)   default()
#  telephone           :string(255)   default()
#  fax                 :string(255)   default()

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_unit_helper'

class ProfileTest < Test::Unit::TestCase
  fixtures :profiles, :settings

  # Replace this with your real tests.
  def setup
    @model = Profile
    @record_one = Profile.find(1)
    @new_obj = {
      :bio => 'I am awesome',
            :user_id => 1,
      :address_line1 => ' 1600 Pennsylvania Avenue NW',
      :address_line2 => 'bunker #4',
      :city => 'Washington',
      :job_title=>'Manager',
      :company=>"Uncle Sam's Military Surplus",
      :state=> 'DC',
      :postal_code =>'20500',
      :telephone=>'202-456-1111',
      :fax=>'202-456-2461'
    }
  end
  
  def test_create_profile
    unit_create @model,@new_obj 
  end
  
  def test_destroy_profile
    unit_destroy @model, @record_one.id
  end
  
  def test_update_profile
    @id = @model.find(:first).id
    unit_update @model, @id, @new_obj
  end
  
end
