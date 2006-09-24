class ArticleController < ProtectedController
  verify :method => :post, :only => [ :shred ],
          :redirect_to => { :action => :index }

  @@article_404 = "Could not find article."
  def read
    @article = find_article_by( params[:id] )
    unless current_user.is_admin?

      raise ActiveRecord::RecordNotFound unless current_user.accessible_articles.include?(@article)
      #raise error if a user tries to view an article which is not published and they are not an admin or the author.
      raise ActiveRecord::RecordNotFound  if !@article.published? && @article.user_id != current_user.id
    end
      
    render :action=>'read' and return if @category = Category.find(@article.category_id)      
  rescue
    flash[:notice] = @@article_404
    redirect_to :controller=>'inbox'
  end
  
  def write
    #todo :not sure you should create a category here.
    Article.with_scope(:find => { :conditions => "user_id = #{current_user.id}", :limit => 1 }) do 
      begin
        @article = find_article_by params[:id] if params[:id]
      rescue
        flash[:notice] = 'Could not find article'
      end
    end
    @article = Article.new unless @article
    if @article.new_record? || @article.category_id.nil?
      @category =  (params[:category_id])? Category.find(params[:category_id]) : Category.new
    else
      @category = Category.find(@article.category_id)
    end
    if request.post?
      
      @potential_groups = []
      #don't allow the user_id to be passed in as a param.
      params[:article].delete('user_id') unless params[:article][:user_id].nil? 
      @article.user_id = current_user.id if @article.new_record?
      unless params[:article][:group_ids].nil?
        @potential_groups = params[:article][:group_ids] 
        params[:article].delete('group_ids')
      end
        
      @article.published_at = Time.now.to_s if params[:commit] == "Save And Publish"
      if @article.update_attributes(params[:article])
        @added, @removed  = update_has_many_collection( @article, 'groups', @potential_groups )
        flash[:notice] = "\"#{@article.title}\" was saved."
        flash[:notice] << "<br/>Added (#{@added.size}) groups and removed (#{@removed.size})" if defined?(@added) && defined?(@removed)
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
