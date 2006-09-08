class ArticleController < ProtectedController
  verify :method => :post, :only => [ :shred ],
          :redirect_to => { :action => :index }


  def read
    if @article = find_article_by( params[:id] )
      if @article.published? || @article.user_id == current_user.id
        render :action=>'read' and return
      else
        raise ActiveRecord::RecordNotFound
      end
    end
    raise ActiveRecord::RecordNotFound
  end
  
  def write
    Article.with_scope(:find => { :conditions => "user_id = #{current_user.id}", :limit => 1 }) do 
      begin
        @article = find_article_by params[:id] if params[:id]
      rescue
        flash[:notice] = 'Could not find article'
      end
    end
    @article = Article.new unless @article
    if request.post?
      if @article.update_attributes(params[:article])
        flash[:notice] = "\"#{@article.title}\" was saved."
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
        flash[:notice] = 'Could not find article'
      end
    end
  end
    
  def comment_on
    Article.with_scope(:find => { :conditions => "allow_comments = true", :limit => 1 }) do 
      begin
        @article = find_article_by params[:id]
        unless @article.nil?
          params[:comment][:parent_id] = @article.id
          @comment = Comment.create(params[:comment])
          flash[:notice] = "Your comment was added." if  @comment.valid?
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
