# = RAM Web Services API: Assets
#
# Endpoint URL (XML-RPC):
#
#   http://<your_host>/services/api
#
# WSDL URL (SOAP): 
#
#   http://<your_host>/services/service.wsdl

class AssetsService < ProtectedWebService
  web_service_api AssetsApi

  # == assets.get
  #
  # Get asset records given their IDs.  
  #
  # === Arguments
  #
  #   username (required): username
  #   password (required): password
  #   ids      (required): array of asset IDs
  #
  # === Returns
  #
  #   Array of AssetStruct objects
  #
  def get(username, password, ids)
    Asset.find(ids).map do |asset|
      WebServiceStructs::AssetStruct.new(
        :id           => asset.id,
        :filename     => asset.filename,
        :content_type => asset.content_type,
        :content      => asset.data,
        :size         => asset.size,
        :description  => asset.description,
        :created_on   => asset.created_on,
        :updated_on   => asset.updated_on
      )
    end
  end

  # == assets.update
  #
  # Update all attributes of an asset (bulk update).
  #
  # === Arguments
  #
  #   username     (required): username
  #   password     (required): password
  #   id           (required): ID of Asset 
  #   asset_struct (required): AssetStruct object representing the new values to assign to the asset.
  #
  #     The following fields are ignored:
  #
  #       created_on
  #       updated_on
  #
  #     updated_on is automatically updated when this call updates any of the Asset's attributes.
  #
  # === Returns
  #
  #   Nothing
  #
  def update(username, password, id, new_asset_obj)
    raise NotImplementedError, "Not implemented"
  end

  # == assets.find
  #
  # Not implemented
  #
  def search(args)
    raise NotImplementedError, "Not implemented"
  end

end
