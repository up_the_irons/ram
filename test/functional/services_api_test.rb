require File.dirname(__FILE__) + '/../test_helper'
require 'services_controller'

class ServicesController; def rescue_action(e) raise e end; end

class ServicesControllerApiTest < Test::Unit::TestCase
  fixtures :attachments, :users, :collections

  def setup
    @controller = ServicesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_echo
    result = invoke_layered :test, :echo, 'hello'
    assert_equal 'hello', result
  end

  def test_null
    result = invoke_layered :test, :null
    assert_nil result
  end

  def test_assets_get
    user  = users(:administrator)
    asset = attachments(:attachment_1)

    result = invoke_layered :assets, :get, user.login, 'qazwsx', [asset.id]
    assert_not_nil  result
    assert_equal 1, result.size

    result_asset = result.first

    assert_equal asset.id,           result_asset.id
    assert_equal asset.filename,     result_asset.filename
    assert_equal asset.content_type, result_asset.content_type
    assert_equal asset.size,         result_asset.size
    assert_equal asset.description,  result_asset.description
    assert_equal asset.created_on,   result_asset.created_on
    assert_equal asset.updated_on,   result_asset.updated_on
  end

  def test_assets_get_bad_login
    user  = OpenStruct.new(:login => 'lskdjfldjskf', :password => '')
    asset = attachments(:attachment_1)

    assert_raises(RuntimeError) do
      result = invoke_layered :assets, :get, user.login, user.password, [asset.id]
    end
  end

  def test_assets_update
  end

  def test_assets_update_bad_login
    user  = OpenStruct.new(:login => 'lskdjfldjskf', :password => '')
    asset = attachments(:attachment_1)

    assert_raises(RuntimeError) do
      result = invoke_layered :assets, :update, user.login, user.password, asset.id, WebServiceStructs::AssetStruct.new(:filename => 'blah')
    end
  end

  def test_categories_get
    user     = users(:administrator)
    category = collections(:collection_30)

    result = invoke_layered :categories, :get, user.login, 'qazwsx', [category.id]
    assert_not_nil  result
    assert_equal 1, result.size

    result_category = result.first

    assert_equal category.id,           result_category.id
    assert_equal category.parent_id,    result_category.parent_id
    assert_equal category.name,         result_category.name
    assert_equal category.description,  result_category.description
    assert_equal category.user_id,      result_category.user_id
    assert_equal category.public,       result_category.public
    assert_equal category.permanent,    result_category.permanent
  end

end
