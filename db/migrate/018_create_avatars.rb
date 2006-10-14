class CreateAvatars < ActiveRecord::Migration
  def self.up
    create_table :avatars do |t|
      # t.column :name, :string
      t.column :content_type, :string
      t.column :filename, :string     
      t.column :size, :integer
      
      # used with thumbnails, always required
      t.column :parent_id,  :integer 
      t.column :thumbnail, :string
      
      # required for images only
      t.column :width, :integer  
      t.column :height, :integer
      t.column :user_id, :integer
      t.column :db_file_id, :integer
    end
  end

  def self.down
    drop_table :avatars
  end
end
