class FeedController < ProtectedController
  before_filter :basic_auth_required
  layout "application", :except => [:category]
  def category
    #breakpoint
    category_contents(params)
    #set the current_user nil because it will bomb if they navigate to the main site while this session is still active.
    self.current_user = nil
    session[:nil]
  rescue
    render :text=>'Could not find feed.', :status=>'404 File Not Found'
    
    self.current_user = nil
    session[:nil]
  end
  
  
  protected
  # Snipped from http://rails.techno-weenie.net/tip/2005/12/14/authentication_for_rss_feeds
  # Thank you technoweenie
  
  def basic_auth_required(realm='Web Password', error_message="Could not authenticate you")
    return true if self.current_user
    username, passwd = get_auth_data
    # check if authorized
    # try to get user
    #unless session[:user] = User.authenticate(username, passwd)
    self.current_user = User.authenticate(username, passwd)
    unless current_user && current_user.account_active?
      # the user does not exist or the password was wrong
      headers["Status"] = "Unauthorized"
      headers["WWW-Authenticate"] = "Basic realm=\"#{realm}\""
      render :text => error_message, :status => '401 Unauthorized'
    end
  end


  private
  def get_auth_data
    user, pass = '', ''
    # extract authorisation credentials
    if request.env.has_key? 'X-HTTP_AUTHORIZATION'
      # try to get it where mod_rewrite might have put it
      authdata = request.env['X-HTTP_AUTHORIZATION'].to_s.split
    elsif request.env.has_key? 'HTTP_AUTHORIZATION'
      # this is the regular location
      authdata = request.env['HTTP_AUTHORIZATION'].to_s.split
    end

    # at the moment we only support basic authentication
    if authdata and authdata[0] == 'Basic'
      user, pass = Base64.decode64(authdata[1]).split(':')[0..1]
    end
    return [user, pass]
  end
end