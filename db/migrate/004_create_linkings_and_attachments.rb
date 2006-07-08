class CreateLinkingsAndAttachments < ActiveRecord::Migration
  def self.up
    create_table :linkings do |t|
		  t.column :user_id       , :integer
		  t.column :category_id   , :integer
		  t.column :group_id      , :integer
		  t.column :linkable_id   , :integer
		  t.column :linkable_type , :string
		  t.column :created_on    , :datetime
		  t.column :updated_on    , :datetime
    end
    
	  create_table :attachments, :force => true do |t|          
      #fields required by acts_as_attachment
      t.column :content_type    , :string,  :limit => 100
      t.column :filename        , :string
      t.column :size            , :integer

      #required for files stored in a DB
      t.column :db_file_id      , :integer
      
      #required for assets stored in a local path
      t.column :path            , :string

      #fields required only for assets with thumbnails
      t.column :parent_id       , :integer
      t.column :thumbnail       , :string

      #fields required only for assets that are images
      t.column :width           , :integer
      t.column :height          , :integer
      t.column :image_format    , :string
      t.column :aspect_ratio    , :float
      t.column :depth           , :integer
      t.column :colors          , :integer
      t.column :colorspace      , :string
      t.column :resolution      , :string
      
      #requirements that are good for you
      t.column :description     , :text
      t.column :user_id         , :integer
      t.column :created_on      , :datetime
      t.column :updated_on      , :datetime
      t.column :type            , :string
     end
     create_table "db_files", :force => true do |t|
       t.column :data, :binary, :size => 10000000, :null => false
     end
     #Dirty hack for mysql because rails defaults to just "blob", which is too small for most images.
     execute "ALTER TABLE `db_files` MODIFY `data` MEDIUMBLOB"
     
  end

  def self.down
    drop_table :attachments
    drop_table :db_files
    drop_table :linkings
  end
end
