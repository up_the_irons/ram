# Schema as of Tue Sep 05 23:25:32 PDT 2006 (schema version 15)
#
#  id                  :integer(11)   not null
#  content_type        :string(100)   
#  filename            :string(255)   
#  size                :integer(11)   
#  db_file_id          :integer(11)   
#  path                :string(255)   
#  parent_id           :integer(11)   
#  thumbnail           :string(255)   
#  width               :integer(11)   
#  height              :integer(11)   
#  image_format        :string(255)   
#  aspect_ratio        :float         
#  depth               :integer(11)   
#  colors              :integer(11)   
#  colorspace          :string(255)   
#  resolution          :string(255)   
#  description         :text          
#  user_id             :integer(11)   
#  created_on          :datetime      
#  updated_on          :datetime      
#  type                :string(255)   
#  category_id         :integer(11)   
#

#class Asset < Attachment
class Asset < ActiveRecord::Base  
  acts_as_attachment
  acts_as_taggable
  set_table_name "attachments"
   # has_and_belongs_to_many :access_contexts, :table_name=>'access_contacts_attachments', :foreign_key=>'access_context'
   #has_and_belongs_to_many :access_contexts,
   #                         :join_table=>'access_contexts_attachments', 
   #                         :foreign_key=>'attachment_id', 
   #                        :class_name=>"AccessContext", 
   #                        :table_name=>"attachments"
   
   has_many :linkings, :as =>:linkable,:dependent => :destroy
   has_many :groups, :through=> :linkings do
    def << (group)
      return if @owner.groups.include?group
      l = Linking.create(
          :linkable_id => @owner.id,
          :linkable_type => "Asset",
          :group_id => group.id
  	    )
  	  l.errors.each_full { |msg| puts msg } unless l.save 
    end
    
   end
   
   belongs_to :category
   belongs_to :user

   #TODO: make this validation work
   #validates_uniqueness_of :filename, :scope => [:groups]
   def name
     filename
  end

   def tags= (str)
     arr = str.split(",").uniq
     self.tag_with arr.map{|a| a}.join(",") unless arr.empty?
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
    
   class << self    
     def search(query, groups)
       groups = [groups].flatten

       find(:all, :select => "attachments.*", :joins => "INNER JOIN linkings ON attachments.id = linkings.linkable_id", :conditions => ["linkings.group_id IN (#{groups.join(',')}) AND (linkings.linkable_type='Asset') AND (attachments.filename LIKE ? OR attachments.description LIKE ? OR (SELECT tags.name FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = attachments.id AND taggings.taggable_type = 'Asset' AND tags.name LIKE ?) IS NOT NULL)", "%#{query}%", "%#{query}%", "%#{query}%"], :group => "attachments.id")
     end

     def find_with_data(quantity, options = {})
       find quantity, options.merge(:select => 'attachments.*, db_files.data', :joins => 'LEFT OUTER JOIN db_files ON attachments.db_file_id = db_files.id')
     end

     def find_by_full_path(full_path)
       pieces   = full_path.split '/'
       filename = pieces.pop
       path     = pieces.join '/'
       find_with_data :first, :conditions => ['path = ? and filename = ?', path, filename]
     end
      def mime_type (ext)
    		re = /(\.)/
    		md = re.match(ext)
    		type = case md.post_match.downcase
    				when "hqx"  : "application/mac-binhex40"
    				when "doc"  : "application/msword"
    				when "exe"  : "application/octet-stream"
    				when "pdf"  : "application/pdf"
    				when "prf"  : "application/pics-rules"
    				when "ai"   : "application/postscript"
    				when "eps"  : "application/postscript"
    				when "ps"   : "application/postscript"
    				when "rtf"  : "application/rtf"
    				when "xla"  : "application/vnd.ms-excel"
    				when "xlc"  : "application/vnd.ms-excel"
    				when "xlm"  : "application/vnd.ms-excel"
    				when "xls"  : "application/vnd.ms-excel"
    				when "xlt"  : "application/vnd.ms-excel"
    				when "xlw"  : "application/vnd.ms-excel"
    				when "pot"  : "application/vnd.ms-powerpoint"
    				when "pps"  : "application/vnd.ms-powerpoint"
    				when "ppt"  : "application/vnd.ms-powerpoint"
    				when "dcr"  : "application/x-director"
    				when "dir"  : "application/x-director"
    				when "dxr"  : "application/x-director"
    				when "dvi"  : "application/x-dvi"
    				when "gtar" : "application/x-gtar"
    				when "gz"   : "application/x-gzip"
    				when "js"   : "application/x-javascript"
    				when "zip"  : "application/zip"
    				when "au"   : "audio/basic"
    				when "snd"  : "audio/basic"
    				when "mid"  : "audio/mid"
    				when "rmi"  : "audio/mid"
    				when "mp3"  : "audio/mpeg"
    				when "m3u"  : "audio/x-mpegurl"
    				when "wav"  : "audio/x-wav"
    				when "bmp"  : "image/bmp"
    				when "gif"  : "image/gif"
    				when "jpe"  : "image/jpeg"
    				when "jpeg" : "image/jpeg"
    				when "jpg"  : "image/jpeg"
    				when "jfif" : "image/pipeg"
    				when "tif"  : "image/tiff"
    				when "tiff" : "image/tiff"
    				when "htm"  : "text/html"
    				when "html" : "text/html"
    				when "txt"  : "text/plain"
    				when "mp2"  : "video/mpeg"
    				when "mpa"  : "video/mpeg"
    				when "mpe"  : "video/mpeg"
    				when "mpeg" : "video/mpeg"
    				when "mpg"  : "video/mpeg"
    				when "mpv2" : "video/mpeg"
    				when "mov"  : "video/quicktime"
    				when "qt"   : "video/quicktime"
    				when "avi"  : "video/x-msvideo"
    				else "application/octet-stream"
    			end
    	end
    	
    	#Adobe Flash 8 uses a nonstandard syntax for their multipart form posts
    	#Acts_as_attachment expects the standard format, which this method simulates through an open struct
    	def translate_flash_post(filedata)
    	  translated = Struct.new(:content_type,:original_filename,:read)
        t = translated.new( "#{Asset.mime_type(filedata.original_filename)}",
                            "#{filedata.original_filename.gsub(/[^a-zA-Z0-9.]/, '_')}",
                            filedata.read
                          )
      end
   end
end

