module RamTestHelper
  def an_asset(opts={},file=nil)
    file = "#{RAILS_ROOT}/test/fixtures/images/rails.png" if file.nil?
    temp_file = uploaded_jpeg(file)
    o = {:description=>"I made this asset on #{Time.now.to_s}", :category_id=>Category.find(:first), :user_id=>1, :uploaded_data=>temp_file}.merge(opts)
    Asset.create(o)
  end
  
  def an_article(opts={})
    user = User.find(:first)
    o = {:category_id=>user.categories[0].id,:user_id=>1,:title=>"Game Time is #{Time.now.to_s}",:body=>"My favorite time to play game is #{Time.now.to_s}" }.merge(opts)
    Article.create(o)
  end
  
  def a_group(opts={})
    o ={:user_id=>User.find(:first).id,:name=>"A Group for game fans born on: #{Time.now.to_s}",:description=>"We were all born on: #{Time.now.to_s}",:public=>true}.merge(opts)
    Group.create(o)
  end
  
  def a_category(opts={})
    o ={:user_id=>User.find(:first).id,:name=>"Category #{Time.now.to_s}",:description=>"This category contains assets about #{Time.now.to_s}",:public=>true}.merge(opts)
    Category.create(o)
  end
  
  def a_comment(opts={})
    o = {:user_id=>User.find(:first).id,:title=>"Game Time is #{Time.now.to_s}",:body=>"My favorite time to play game is #{Time.now.to_s}"}.merge(opts)
    Comment.create(o)
  end
  
  def create_user(opts = {})
    o = { :login => 'quire', :email => 'quire@example.com', :password => 'qazwsx', :password_confirmation => 'qazwsx' }.merge(opts)
    User.create(o)
  end
end