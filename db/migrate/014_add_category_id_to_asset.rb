class AddCategoryIdToAsset < ActiveRecord::Migration
  def self.up
    add_column :attachments, :category_id, :integer
  end

  def self.down
    remove_column :attachments, :category_id
  end
end
