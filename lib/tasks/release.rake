# $Id$
#
# Rake tasks for creating bundled distribution files for RAM
#
# Created: 11-30-2006  Author: Garry Dolley

DIST_DIR = RAILS_ROOT + '/dist'
TMP_DIR  = DIST_DIR   + '/tmp'

SVN_INFO = YAML.load(`svn info`)

desc "Create bundled distribution files (.tar.gz, .gem, .zip) for a new release of RAM"
task :release => [:make_dirs] do
  @releases = `svn list svn://svn.locusfoc.us/ram/tags`

  puts <<-STUFF

Current tagged releases:

#{@releases}
  STUFF

  loop do
    print "What new version number would you like to release? (ex: 0.9.2) : "
    break if (@ver = STDIN.gets.chomp) =~ /^\d+\.\d+(\.\d+)*$/ 
    puts  "Bad format, use only numbers and periods" if @ver
  end

  @rev = SVN_INFO['Revision']

  puts ""
  puts "I detect your current working copy revision to be: #{@rev}"
  puts ""

  loop do
    print "Enter the revision number to release or leave blank to use revision above [ENTER=#{@rev}] : "
    break if (@input_rev = STDIN.gets.chomp) =~ /^\d*$/ 
    puts  "Bad format, use only numbers or hit ENTER to accept the default" if @ver
  end

  @rev = @input_rev unless @input_rev.empty?

  puts ""
  loop do
    print "What directory off the repository root should I release? [ENTER=trunk] : "
    break if (@dir = STDIN.gets.chomp) =~ /^.*$/ 
  end

  @dir = 'trunk' if @dir.empty?

  @source = SVN_INFO['Repository Root'] + '/' + @dir
  @tag    = 'RELEASE_' + @ver.gsub(/\./, '_')  
  @file   = "ram_#{@ver}"

  print <<-STUFF

Release Summary
---------------

Version  : #{@ver}
Revision : #{@rev}
Directory: #{@source}
Tag      : #{@tag}  

If everything looks OK, we are ready to make a new release.

  STUFF

  print "Would you like to continue? [y/N] : "

  exit unless STDIN.gets =~ /^[yY]$/

  puts "\nExporting from Subversion...\n"
  `svn export #{@source}@#{@rev} #{TMP_DIR}/#{@file}`

  puts "\nRepacking icons...\n"
  `cd #{TMP_DIR}/#{@file}/public/images ; rm -f icons ; svn export #{SVN_INFO['Repository Root'] + '/icons'} icons`
  
  puts "\nCreating distribution files...\n"
  `cd #{TMP_DIR} ; tar cvzf #{DIST_DIR}/#{@file}.tar.gz #{@file}`
  `cd #{TMP_DIR} ; zip -r #{DIST_DIR}/#{@file}.zip #{@file}`

  puts "\nTagging the release in Subversion...\n"
  `svn copy -r #{@rev} #{@source} #{SVN_INFO['Repository Root'] + '/tags/' + @tag} -m 'Tagged #{@ver} release'`

  puts "\nRelease complete!\n"
  `rm -rf #{TMP_DIR}`

  puts "\nLook in #{DIST_DIR} for your new files. :)"
end

task :make_dirs => [:make_dist_dir, :make_tmp_dir]

task :make_dist_dir do
  unless File.exist?(DIST_DIR)
    begin
      Dir.mkdir(DIST_DIR, 0775)
    rescue => boom
      puts "Cannot make distribution directory: #{boom.message}"
      exit
    end
  end

  `rm -rf #{DIST_DIR}/*`
end

task :make_tmp_dir do
  unless File.exist?(TMP_DIR)
    begin
      Dir.mkdir(TMP_DIR, 0775)
    rescue => boom
      puts "Cannot make temporary directory: #{boom.message}"
      exit
    end
  end

  `rm -rf #{TMP_DIR}/*`
end
