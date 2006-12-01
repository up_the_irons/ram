class Reader < ActiveRecord::Base
  acts_as_subscribable :subscribe_to => 'Books'
end
