# $Id$
#
# Rake Install Tasks for RAM
#
# Created: 10-07-2006  Author: Garry Dolley

DB_CONFIG = 'config/database.yml'

DB_ADAPTERS = [
  { :mysql          => 'MySQL'           },
  { :postgresql     => 'PostgreSQL'      },
  { :sqlite         => 'SQLite'          },
  { :sqlite3        => 'SQLite3'         },
  { :firebird       => 'Firebird'        },
  { :sqlserver      => 'SQL Server'      },
  { :sqlserver_odbc => 'SQL Server ODBC' },
  { :db2            => 'DB2'             },
  { :oracle         => 'Oracle'          },
  { :sybase         => 'Sybase'          },
  { :openbase       => 'OpenBase'        }
]

file DB_CONFIG do
  puts ""
  puts "Select your database adapter:\n\n"

  DB_ADAPTERS.each_with_index do |db, num|
    puts "#{num+1}. #{db.to_a[0][1]}"
  end
  
  puts  ""

  ch = ''
  loop do
    print ": "
    break if (ch = STDIN.gets) =~ /^[1-9][0-9]*$/ and !DB_ADAPTERS[ch.to_i - 1].nil?
  end

  adapter = DB_ADAPTERS[ch.to_i - 1].to_a[0][0]

  puts ""
  puts "Create an empty database with your #{DB_ADAPTERS[ch.to_i - 1].to_a[0][1]} admin tool and then enter"
  puts "the following:"
  puts  ""

  db_name = ''
  loop do
    print "Database Name: "
    break if (db_name = STDIN.gets.chomp) =~ /^.+$/ # At least 1 character in length excluding newline
  end

  db_username = ''
  loop do
    print "Database Username: "
    break if (db_username = STDIN.gets.chomp) =~ /^.+$/ 
  end

  db_password = ''
  loop do
    print "Database Password: "
    break if (db_password = STDIN.gets.chomp) =~ /^.+$/ 
  end

  db_hostname = ''
  loop do
    print "Database Hostname [ENTER=localhost] : "
    break if (db_hostname = STDIN.gets.chomp) =~ /^.*$/ 
  end

  db_hostname = 'localhost' if db_hostname == ''

  puts ""
  puts "Creating config/database.yml..."
  File.open(DB_CONFIG, "w") do |f|
    f.puts <<-CONFIG
# Database configuration file for Ruby Asset Manager (RAM)

production:
  adapter: #{adapter}
  database: #{db_name}
  username: #{db_username}
  password: #{db_password}
  host: #{db_hostname}

development:
  production
    CONFIG
  end
end

task :check_for_db_config_file do
  if File.exists?(DB_CONFIG)
    puts  ""
    puts  "Looks like #{DB_CONFIG} already exists"
    puts  ""
    print "Would you like to delete this file and start over? [y/N] : "

    File.delete(DB_CONFIG) if STDIN.gets =~ /^[yY]$/
  end
end

task :pre_migrate do
  puts ""
  puts "Last Step!"
  puts ""
  puts "We need to run the Rake migrate task to set up the default database schema."
  puts "This may generate a page or two of output, which you can ignore, unless the"
  puts "migration fails."
  puts ""
  puts "If this step fails, the installer will exit. You must correct the problem"
  puts "causing the failing migration and run this installer again."
  puts ""

  print "Press ENTER to continue..."
  STDIN.getc

  puts ""
  puts "Migrating..."
end

task :post_migrate do
  puts ""
  puts "Migration complete."
end

task :banner do
  puts <<-BANNER
Ruby Asset Manager (RAM) Installer v0.8
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Welcome and thank you for choosing Ruby Asset Manager for your digital
asset management needs!  

This installer will configure your initial RAM system using sensible
defaults and will only ask questions when the answer cannot be inferred
or a conflict arises.  

So that you know what is going on behind the scenes, here's what will
happen:

  1. Create config/database.yml
  2. Create database schema
  3. WEBrick web server will start (optional)

  BANNER

  print "Are you ready to continue? [Y/n] : "

  ch = STDIN.gets

  exit unless ch =~ /^[yY\n]$/
end

desc "Configure and install RAM for the first time"
task :install => [:banner, :check_for_db_config_file, DB_CONFIG, :pre_migrate, :migrate, :post_migrate] do
  puts  ""
  puts  "Congratulations!  Your Ruby Asset Manager is ready to go!"
  puts  ""
  puts  "Would you like to start RAM on port 20212 so you can begin playing with it"
  print "right away? [Y/n] : "

  ch = STDIN.gets

  server_start_cmd = "./script/server webrick -p 20212"

  if ch =~ /^[yY\n]$/
    puts ""
    puts "You can run this again in the future with the commands:"
    puts server_start_cmd
    puts ""
    puts "Starting WEBrick..."

    %x{#{server_start_cmd} > /dev/null 2>&1 &}
    sleep 1 # :)

    puts ""
    puts "----"
    puts "Point your browser to: http://" + `hostname`.chomp + ":20212"
    puts ""
    puts "The default login credentials are:"
    puts ""
    puts "Username: admin"
    puts "Password: admin"
  end

  puts ""
  puts "Installation complete."
  puts ""
  puts "Have a great day and thanks for installing RAM -- Mark & Garry"
end
