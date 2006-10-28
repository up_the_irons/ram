module GBase
  def self.included(base) #:nodoc:
    def base.included(base)
      class_eval <<-EOF
        super
        base.extend(ClassMethods) if defined? ClassMethods
      EOF
    end
  end  

  def self.ids_to_string(*ids)
    s = ''; ids.each { |id| s += ":#{id}," }; s.chop!
  end

  def default_url_options(options)
    {}
  end
end
