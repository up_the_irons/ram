# $Id$
#
# Rake tasks for creating bundled distribution files for RAM
#
# Created: 11-30-2006  Author: Garry Dolley

desc "Create bundled distribution files (.tar.gz, .gem, .zip) for a new release of RAM"
task :release do
  @releases = `svn list svn://svn.locusfoc.us/ram/tags`

  puts <<-STUFF

Current tagged releases:

#{@releases}
  STUFF

  loop do
    print "What new version number would you like to release? (ex: 0.9.2) : "
    break if (@ver = STDIN.gets.chomp) =~ /^.+$/ 
  end

end
