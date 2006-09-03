class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      t.column :parent_id       , :integer
      t.column :category_id     , :integer
      t.column :user_id         , :integer
      t.column :title           , :string
      t.column :permalink       , :string
      t.column :excerpt         , :text
      t.column :body            , :text
      t.column :excerpt_html    , :text
      t.column :body_html       , :text
      t.column :created_at      , :datetime
      t.column :updated_at      , :datetime
      t.column :published_at    , :datetime
      t.column :published_at    , :datetime
      t.column :children_count  , :integer
      t.column :type            , :string
      t.column :allow_comments  , :boolean , :default=>false
      t.column :status          , :integer , :default => 0, :null => false
    end
  end

  def self.down
    drop_table :articles
  end
end
