class Reader < ActiveRecord::Base
  acts_as_subscribable :subscribe_to => [:books,:magazines]
end
