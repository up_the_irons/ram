class AddCompanyAndJobTitleToProfile < ActiveRecord::Migration
  def self.up
    add_column :profiles, :job_title , :string, :default=>""
    add_column :profiles, :company   , :string, :default=>""
  end

  def self.down
    remove_column :profiles, :job_title
    remove_column :profiles, :company
  end
end
