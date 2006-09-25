class AddProtectedKeyToCollections < ActiveRecord::Migration
  def self.up
    add_column :collections, :permanent, :boolean
  end

  def self.down
    remove_column :collections, :permanent
  end
end
