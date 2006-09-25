module TagMethods
  def self.included(base)

    # We have to make sure we overwrite the tags() method that acts_as_taggable puts in, so we define tags in the 
    # context of the including class
    base.class_eval do
      def tags
        if id and !new_record?
          Tag.find(:all, :joins => "tags INNER JOIN taggings ON tags.id = taggings.tag_id",
                         :conditions => "taggings.taggable_id = #{id} AND taggings.taggable_type = '#{self.class.name}'")
        else
          []
        end
      end
    end
  end
end
