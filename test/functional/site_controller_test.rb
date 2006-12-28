require File.dirname(__FILE__) + '/../test_helper'
require 'site_controller'

# Re-raise errors caught by the controller.
class SiteController; def rescue_action(e) raise e end; end

class SiteControllerTest < Test::Unit::TestCase
  fixtures :settings
  def setup
    @controller = SiteController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_rmagick_dependency
    assert !$APPLICATION_SETTINGS.preferences[:rmagick].nil?
  end
end
