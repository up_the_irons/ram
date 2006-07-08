class AddParentIdToCollections < ActiveRecord::Migration
  def self.up
  	add_column :collections, :parent_id, :integer
	add_column :collections, :counter_cache, :boolean, :default=>true
  end

  def self.down
  	remove_column :collections, :parent_id 
  	remove_column :collections, :counter_cache
  end
end
