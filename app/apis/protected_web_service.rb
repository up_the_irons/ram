class ProtectedWebService < ActionWebService::Base #:nodoc:
  before_invocation :authenticate

  protected

  def authenticate(name, args) #:nodoc:
    if User.authenticate(args[0], args[1]).nil?
      raise "1000: Authentication Failed"
    end
  end
end
