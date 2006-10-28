class AddAdditionalFeedAttributes < ActiveRecord::Migration
  def self.up
    add_column :feeds, :is_local   , :boolean, :default=>true
    add_column :feeds, :local_path , :string
  end

  def self.down
    remove_column :feeds, :is_local
    remove_column :feeds, :local_path
  end
end
