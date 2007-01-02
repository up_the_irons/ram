# = RAM Web Services API: Categories
#
# Endpoint URL (XML-RPC):
#
#   http://<your_host>/services/api
#
# WSDL URL (SOAP): 
#
#   http://<your_host>/services/service.wsdl

class CategoriesService < ProtectedWebService
  web_service_api CategoriesApi

  # == categories.get
  #
  # Get category records given their IDs.  
  #
  # === Arguments
  #
  #   username (required): username
  #   password (required): password
  #   ids      (required): array of category IDs
  #
  # === Returns
  #
  #   Array of CategoryStruct objects
  #
  def get(username, password, ids)
    # TODO: Flesh this out
    Category.find(ids).map do |category|
      WebServiceStructs::CategoryStruct.new(
        :id           => category.id,
        :parent_id    => category.parent_id,
        :name         => category.name,
        :description  => category.description,
        :user_id      => category.user_id,
        :public       => category.public,
        :permanent    => category.permanent
      )
    end
  end

end
