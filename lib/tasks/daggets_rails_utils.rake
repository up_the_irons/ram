task :start_fresh => :environment do
     Rake::Task[:clear_logs].invoke
     puts 'clearing logs                           ...done'
     
     Rake::Task[:recreate_database].invoke
     puts 'recreate test database                  ...done'
     puts 'recreate development database           ...done'
     
     ActiveRecord::Base.establish_connection(:development)
     Rake::Task[:migrate].invoke
     puts 'migrate the development database        ...done'
     
     Rake::Task[:load_fixtures_to_development].invoke
     puts 'load fixtures into development database ...done'
     
     ActiveRecord::Base.establish_connection(:test)
     Rake::Task[:prepare_test_database].invoke
     puts 'clone the development structure to test ...done'
end

desc "Load fixtures data into the test database"
task :load_fixtures_to_development => :environment do
  require 'active_record/fixtures'
  ActiveRecord::Base.establish_connection(:development)
  Dir.glob(File.join(RAILS_ROOT, 'test', 'fixtures', '*.{yml,csv}')).each do |fixture_file|
    Fixtures.create_fixtures('test/fixtures', File.basename(fixture_file, '.*'))
  end
end

task :recreate_database => :environment do
  abcs = ActiveRecord::Base.configurations
	tdb = Array.new
  tdb << 'test'
  tdb << 'development'

 	for db in tdb
	  case abcs[db]["adapter"]
	    when "mysql"
	      ActiveRecord::Base.establish_connection(db.to_sym)
	      ActiveRecord::Base.connection.recreate_database(abcs[db]["database"])
	    when "postgresql"
	      ENV['PGHOST']     = abcs[db]["host"] if abcs[db]["host"]
	      ENV['PGPORT']     = abcs[db]["port"].to_s if abcs[db]["port"]
	      ENV['PGPASSWORD'] = abcs[db]["password"].to_s if abcs[db]["password"]
	      enc_option = "-E #{abcs[db]["encoding"]}" if abcs[db]["encoding"]
	      `dropdb -U "#{abcs[db]["username"]}" #{abcs[db]["database"]}`
	      `createdb #{enc_option} -U "#{abcs[db]["username"]}" #{abcs[db]["database"]}`
	    when "sqlite","sqlite3"
	      dbfile = abcs[db]["database"] || abcs[db]["dbfile"]
	      File.delete(dbfile) if File.exist?(dbfile)
	    when "sqlserver"
	      dropfkscript = "#{abcs[db]["host"]}.#{abcs[db]["database"]}.DP1".gsub(/\\/,'-')
	      `osql -E -S #{abcs[db]["host"]} -d #{abcs[db]["database"]} -i db\\#{dropfkscript}`
	      `osql -E -S #{abcs[db]["host"]} -d #{abcs[db]["database"]} -i db\\#{RAILS_ENV}_structure.sql`
	    when "oci"
	      ActiveRecord::Base.establish_connection(db.to_sym)
	      ActiveRecord::Base.connection.structure_drop.split(";\n\n").each do |ddl|
	        ActiveRecord::Base.connection.execute(ddl)
	      end
	    else
	      raise "Task not supported by '#{abcs[db]["adapter"]}'"
	  end
	end
end

desc "Start Application"
task :start do
  system "ruby script/server"
end