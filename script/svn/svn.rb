#!/usr/bin/env ruby
require 'rexml/document'
require 'ostruct'

module Collectivex
  class Svn
    include REXML
    
    attr_accessor :path
    def self.cx_version
      "0.2"
    end
    
    def version
      `svn --version`.match(/version ([\d\.]+) /)[1].to_f
    end
    
    def initialize(branch, new_branch = false, options=OpenStruct.new)
      super()      
      @debug = options.debug
      if version < 1.3
        $stderr.puts "Sorry, this requires subversion >= 1.3.0"
        return false
      end
      
      @path = options.path || File.dirname(__FILE__) + "/../../../branches"
      @branch = branch
      if !new_branch
        if !File.exist?("#{@path}/#{@branch}")
          $stderr.puts "#{@path}/#{@branch} is not a current branch"
          @path = nil
          @branch = nil
          return false
        else
          @path = "#{@path}/#{@branch}"
        end
      else
        # new branch
        @path = nil
      end
    end

    def first_rev
      return unless @path && @branch
      xml = Document.new(`svn log #{@path} --stop-on-copy --xml`)
      xml.elements[1].elements.to_a[-1].attributes['revision']
    end
    
    def last_rev
      return unless @path && @branch
      xml = Document.new(`svn log #{@path} --stop-on-copy --xml`)
      xml.elements[1].elements[1].attributes['revision']
    end
    
    def url
      return unless @path
      xml = Document.new(`svn info #{@path} --xml`)
      xml.elements[1].elements["entry"].elements['url'].text
    end
    
    def root
      return unless @path
      xml = Document.new(`svn info #{@path} --xml`)
      xml.elements[1].elements["entry"].elements['repository'].elements['root'].text
    end
    
    def diff
      return unless @path && @branch
      svn = "svn diff -r #{first_rev}:#{last_rev} #{url}" 
      puts svn
      $stderr.puts `#{svn}` unless @debug
    end
   
    def unbranch
      return unless @path && @branch
      svn = "svn merge #{'--dry-run ' if @debug}-r #{first_rev}:#{last_rev} #{root}/branches/#{@branch} ."
      puts svn
      $stderr.puts `#{svn}`
    end
    
    def branch
      return if @path  
      @path = File.dirname(__FILE__) + "/../../"
      svn = "svn cp #{url} #{root}/branches/#{@branch} -m 'Creating branch for #{@branch} [#{last_rev}]'"
      puts svn
      unless @debug
        $stderr.puts `#{svn}`
        $stderr.puts `cd ../branches; svn up #{@branch}`
        $stderr.puts `svn propset svn:trunk #{last_rev} .`
      end
    end

    def head_rev
      @head_rev ||= Document.new(`svn info #{root}/trunk --xml`).elements[1].elements[1].attributes['revision']
    end

    def last_trunk
      l = `svn propget svn:trunk .`.to_i
      l = first_rev if l == 0
      l
    end

    def head_rev
      @head_rev ||= Document.new(`svn info #{root}/trunk --xml`).elements[1].elements[1].attributes['revision']
    end

    def uptrunk
      svn = "svn diff #{root}/trunk@#{last_trunk} #{root}/trunk@#{head_rev} | less"
      puts svn
      $stderr.puts `#{svn}` unless @debug
    end

    def upmerge
      svn = "svn merge #{root}/trunk@#{last_trunk} #{root}/trunk@#{head_rev}" 
      puts svn
      $stderr.puts `#{svn}` unless @debug
      $stderr.puts `svn propset svn:trunk #{head_rev} .` 
    end

  end
end
