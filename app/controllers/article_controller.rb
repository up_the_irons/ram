class ArticleController < ProtectedController
  verify :method => :post, :only => [ :shred ],
          :redirect_to => { :action => :index }

  @@article_404 = "Could not find article."
  def read
    if @article = find_article_by( params[:id] )
      if @article.published? || @article.user_id == current_user.id || current_user.is_admin?
        @category = Category.find(@article.category_id)
        render :action=>'read' and return
      else
        raise ActiveRecord::RecordNotFound
      end
    end
    raise ActiveRecord::RecordNotFound
  rescue
    flash[:notice] = @@article_404
    redirect_to :controller=>'inbox'
  end
  
  def write
    @category =  (params[:category_id])? Category.find(params[:category_id]) : Category.new
    Article.with_scope(:find => { :conditions => "user_id = #{current_user.id}", :limit => 1 }) do 
      begin
        @article = find_article_by params[:id] if params[:id]
      rescue
        flash[:notice] = 'Could not find article'
      end
    end
    @article = Article.new unless @article
    @article.user_id = current_user.id
    if request.post?
      @article.published_at = Time.now.to_s if params[:commit] == "Save And Publish"
      if @article.update_attributes(params[:article])
        flash[:notice] = "\"#{@article.title}\" was saved."
        redirect_to :action=>'write', :id=>@article.id unless params[:id]  
      end
    end
  end
  
  def shred
    Article.with_scope(:find => { :conditions => "user_id = #{current_user.id}", :limit => 1 }) do 
      begin
        @article = find_article_by params[:id]
        unless @article.nil?
          @article.destroy unless @article.nil?
          flash[:notice] = 'Your Article was deleted.'
        end
      rescue
          flash[:notice] = @@article_404
      end
    end
  end
  
  #expects
  #post :comment_on, :id=>a.id, :comment=>{:user_id=>,:title=>,:body=>''}
  def comment_on
    Article.with_scope(:find => { :conditions => "allow_comments = true", :limit => 1 }) do 
      begin
        @article = find_article_by params[:id]
        unless @article.nil? or request.get?
          params[:comment][:title] = "Comment by #{current_user.login}" unless params[:comment][:title]
          params[:comment][:parent_id] = @article.id
          params[:comment][:user_id] = current_user.id
          @comment = Comment.create(params[:comment])
          raise unless @comment.valid?
          flash[:notice] = "Your comment was added."
          @article.reload
          redirect_to :action=>'read', :id=>@article.id
        end
      rescue
        flash[:notice] = "Your comments were not saved."
      end
    end
  end
  
  protected 
  def find_article_by(param)
    if params[:id].to_s.match(/^\d+$/)
      article = Article.find(param)
    else
      article = Article.find_by_title(param)
    end
  end
end
