# = RAM Web Services API: Assets
#
# Endpoint URL (XML-RPC):
#
#   http://<your_host>/services/api
#
# WSDL URL (SOAP): 
#
#   http://<your_host>/services/service.wsdl

class AssetsService < ActionWebService::Base
  web_service_api AssetsApi

  before_invocation :authenticate

  # == assets.Get
  #
  # Get asset records given their IDs.  
  #
  # === Arguments
  #   username (required): username
  #   password (required): password
  #   ids (required): array of asset IDs
  #
  # === Returns
  #   Array of AssetStruct objects
  #
  def get(username, password, ids)
    Asset.find(ids).map do |asset|
      AssetStruct.new(:id           => asset.id,
                      :filename     => asset.filename,
                      :content_type => asset.content_type,
                      :size         => asset.size,
                      :description  => asset.description,
                      :created_on   => asset.created_on,
                      :updated_on   => asset.updated_on)
    end
  end

  # == assets.Search
  #
  # Not implemented
  #
  def search(args)
    raise NotImplementedError, "Not implemented"
  end

  protected

  def authenticate(name, args) #:nodoc:
    false if User.authenticate(args[0], args[1]).nil?
  end
end
