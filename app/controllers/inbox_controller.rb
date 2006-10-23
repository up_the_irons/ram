class InboxController < ProtectedController
  include FeedReader
  def index
    inbox
  end
  
  def inbox
    @user = User.find(current_user.id)
    render 'inbox/inbox'
  end
end
