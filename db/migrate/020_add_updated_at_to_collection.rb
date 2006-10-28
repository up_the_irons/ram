class AddUpdatedAtToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :created_at , :datetime
    add_column :collections, :updated_at , :datetime
  end

  def self.down
    remove_column :collections, :created_at , :datetime
    remove_column :collections, :updated_at , :datetime
  end
end
