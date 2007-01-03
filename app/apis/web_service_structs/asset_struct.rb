module WebServiceStructs

  # AssetStruct object used by the RAM Web Services API
  #
  # Each asset represented by AssetStruct has the following attributes:
  #
  #   id           : (int)      Unique ID of this asset
  #   filename     : (string)   Filename
  #   content_type : (string)   Content-type (e.g. image/gif, application/pdf, ...)
  #   content      : (string)   File content (UTF8 encoded)
  #   size         : (int)      Size in bytes
  #   description  : (string)   Description
  #   created_on   : (datetime) Creation date and time
  #   updated_on   : (datetime) Last updated date and time
  #
  class AssetStruct < ActionWebService::Struct
    member :id,           :int
    member :filename,     :string
    member :content_type, :string
    member :content,      :string
    member :size,         :int
    member :description,  :string
  
    member :created_on,   :datetime
    member :updated_on,   :datetime
  end
end
