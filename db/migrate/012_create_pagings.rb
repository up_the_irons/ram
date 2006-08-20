class CreatePagings < ActiveRecord::Migration
  @@table_name = 'paging'

  def self.up
    create_table @@table_name do |t|
      t.column :controller,   :string, :limit => 128, :default => '', :null => false
      t.column :action,       :string, :limit => 128, :default => '', :null => false
      t.column :num_per_page, :integer, :default => 10, :null => false
    end

    add_index(@@table_name, [:controller, :action], :unique => true)
  end

  def self.down
    drop_table @@table_name
  end
end
