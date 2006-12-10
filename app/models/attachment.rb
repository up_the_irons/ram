#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

# Base file attachment method
# Used from the attachment class as part of acts_as_attachment
class Attachment < ActiveRecord::Base  
  before_validation :sanitize_path_if_available

  #validates_uniqueness_of :filename, :scope => [:path, :site_id]
  #TODO: Validate_uniqueness with a scope around an access_context
  
  acts_as_attachment

  class << self    
    def find_with_data(quantity, options = {})
      find quantity, options.merge(:select => 'attachments.*, db_files.data', :joins => 'LEFT OUTER JOIN db_files ON attachments.db_file_id = db_files.id')
    end

    def find_by_full_path(full_path)
      pieces   = full_path.split '/'
      filename = pieces.pop
      path     = pieces.join '/'
      find_with_data :first, :conditions => ['path = ? and filename = ?', path, filename]
    end
  end

  # Read from the model's attributes if it's available.
  def data
    read_attribute(:data) || write_attribute(:data, (db_file_id ? db_file.data : nil))
  end

  # set the model's data attribute and attachment_data
  def data=(value)
    self.attachment_data = write_attribute(:data, value)
  end

  def full_path
    (path && filename) ? File.join(path, filename) : (filename || path)
  end

  #module TemplateAndResourceMixin
  # def self.included(base)
  #    base.belongs_to             :site
  #    base.validates_presence_of  :site
  #    base.validate               :path_exists_and_valid?
  # end

  # protected
  #  def path_exists_and_valid?
  #    errors.add(:path, ActiveRecord::Errors.default_error_messages[:blank]) if path.blank?
  #  end
  #end

  protected

  def sanitize_path_if_available
    self.path.gsub!(/^\/+|\/+$/, '') unless path.blank?
  end
end
