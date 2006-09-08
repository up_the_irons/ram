module RamTestHelper
  
  def an_article(opts={})
    Article.create({:user_id=>User.find(:first).id,:title=>"Game Time is #{Time.now.to_s}",:body=>"My favorite time to play game is #{Time.now.to_s}" }.merge(opts))
  end

  def a_comment(opts={})
    o = {:user_id=>User.find(:first).id,:title=>"Game Time is #{Time.now.to_s}",:body=>"My favorite time to play game is #{Time.now.to_s}"}.merge(opts)
    Comment.create(o)
  end
  
  def create_user(options = {})
    o = { :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options)
    User.create(o)
  end
end