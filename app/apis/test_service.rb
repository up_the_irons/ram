class TestService < ActionWebService::Base
  web_service_api TestApi

  # == test.echo
  #
  # A testing method which echo's the first paramater back in the response.
  #
  # === Arguments
  #
  #   string (required): Any string
  #
  # === Returns
  #
  #   string: The string passed in the first parameter
  #
  def echo(str)
    str
  end

  # == test.null
  #
  # Accepts nothing and returns nothing
  #
  def null
  end
end
