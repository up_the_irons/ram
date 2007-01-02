module WebServiceStructs

  # CategoryStruct object used by the RAM Web Services API
  #
  # Each category represented by CategoryStruct has the following attributes:
  #
  #   id           : (int)      Unique ID of this category
  #   parent_id    : (int)      Category ID of parent to this category (0 if no parent)
  #   name         : (string)   Category name
  #   description  : (string)   Description
  #   user_id      : (int)      User ID of owner (creator)
  #   public       : (bool)     Is category public?
  #   permanent    : (bool)     Is category permanent? (cannot be deleted)
  #
  class CategoryStruct < ActionWebService::Struct
    member :id,           :int
    member :parent_id,    :int
    member :name,         :string
    member :description,  :string
    member :user_id,      :int
    member :public,       :bool
    member :permanent,    :bool
  end
end
