#--
# $Id: acts_as_subscribable.rb 1173 2006-12-15 03:16:30Z mark $
#
# Copyright (c) 2006 Mark Daggett
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
# ++
 
 
 # == Has A Collection
 # The "Has A Collection" plugin allows you to extend a model to collect other models (like a has_many relationship)
 # or allow other models to collect it (like a poly morphic belongs_to).
 # The advantage of has_collection over the :through option in has_many is that the associations can be polymorphic on both ends.
 # In a typical polymorphic has_many assocation at least one class still needs to use a "belongs_to" association. 
 # The collection module transparently handles the implicit joins between the two models.
 # The syntax is very readable for example, for class User 'has a collection of blogs' would be written:
 # has_collection :of =>["blogs"] 
 #
 # == Example implementations of has_collection
 # Creates @reader.articles and @reader.comments
 # class Reader < ActiveRecord::Base
 #   has_collection :of => ["blogs","comments"]
 # end
 # 
 # Creates @blogs.articles, @blogs.authors and @reader.blogs
 # Allows only the Reader class to collect to the Blog class.
 # class Blog < ActiveRecord::Base
 #   has_collection :of =>%w(articles authors)
 #   is_collected :by => ["readers"]
 # end
 # 
 # Allows only the Blog class to collect to the Feed class.
 # class Feed
 #   is_collected :by => ["blogs"]
 # end

module ActiveRecord
  module Acts #:nodoc:
    module HasACollection #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)  
      end
      
      module ClassMethods
        OPTIONS = {
                :of => [], 
                :by => [],
                :class_name => "Subscription",
                :table_name => "subscriptions",
                :class_column => nil, 
                :association_column => nil, 
                :before_add => nil, 
                :after_add =>nil, 
                :before_remove => nil, 
                :after_remove => nil
                }.freeze
        # For example reader has_collection of books.        
        def has_collection(opts = {})
          opts.assert_valid_keys( OPTIONS.keys )
          options = OPTIONS.dup
          options = options.merge({:class_column => "subscriber", :association_column => "subscribed_to" }.merge(opts))
          options[:associations] = options[:of]
          create_associations(options) unless options[:of].empty?
        end
        
        # For example, a Book is_collected by readers.
        def is_collected(opts ={})
          opts.assert_valid_keys( OPTIONS.keys )
          options = OPTIONS.dup
          options = options.merge({:by => [], :class_column => "subscribed_to", :association_column => "subscriber" }.merge(opts))
          options[:associations] = options[:by]
          create_associations(options) unless options[:by].empty?
        end

        def create_associations(options)
          self_class    = options[:class_column]
          other_class   = options[:association_column]
          collection_class =  options[:class_name].classify.constantize
          
          # If needed dynamically create the class, which acts as the join model.
          collection_class = create_collection_class(options) unless options[:table_name].to_s.singularize.classify == "Subscription"
          module_eval do
            options[:associations].each do | collection |
              
              # FIXME: In certain cases (like migrations) an observer will trigger a class and try and load it before a table is created to reference it.
              # This hack tries to catch this condition.
              begin
                collection.to_s.singularize.classify.constantize.new
              rescue StatementInvalid
                return false
              end
              counter_sql, sql = create_sql_statements({
                                                        :association_table => collection.to_s.singularize.classify.constantize.class_name.tableize, 
                                                        :association_class => collection.to_s.singularize.classify.constantize,
                                                        :association_column => other_class,
                                                        :class_column => self_class, 
                                                        :table_name => options[:table_name]
                                                        })
              # Dynamically create a has_many association.  
              has_many collection.to_s.pluralize.to_sym, :finder_sql => sql, :counter_sql => counter_sql do
                class_eval <<-endofeval
                  # Class#collections << @record
                  def <<(record)
                    # Ensure unique records of the right class
                    return unless @owner.respond_to?record.class.to_s.tableize.to_sym
                    return unless @owner.send(record.class.to_s.tableize.to_sym, true).map{|x| return false if x.id == record.id}
                    klass = #{collection_class}
                    before_add    = record.class.to_s.downcase << '_before_add'
                    after_add     = record.class.to_s.downcase << '_after_add'
                     
                    @owner.send(before_add, record) if @owner.respond_to? before_add
                    s = #{collection_class}.create(
                      :#{self_class}_id    => @owner.id,
                      :#{self_class}_type  => @owner.class.to_s,
                      :#{other_class}_id   => record.id,
                      :#{other_class}_type => record.class.to_s
                    )
                    # Force the reload of the association
                    @owner.send(after_add, record) if @owner.respond_to? after_add
                    @owner.send(record.class.to_s.tableize.to_sym, true)
                  end
                  
                  # Class#collections.delete @record
                  def delete(record)
                    before_remove = record.class.to_s.downcase << '_before_remove'
                    after_remove  = record.class.to_s.downcase << '_after_remove'
                    record.each{| x | @owner.send(@reflection.name, send('delete',record[x] ))} if record.is_a?(Array)
                    s = #{collection_class}.find :first, :conditions =>create_delete_sql( '#{self_class}', '#{other_class}', record )
                    return false unless s
                    #{collection_class}.transaction do
                      @owner.send(before_remove,record) if @owner.respond_to? before_remove
                      return false unless s.destroy
                      @owner.send(record.class.to_s.tableize.to_sym, true)
                      @owner.send(after_remove,record) if @owner.respond_to? after_remove
                    end
                    
                  end
                endofeval
                
                # Class#collections.build @record
                def build(*args)
                  reflection = @reflection.name.to_s.singularize.classify.constantize
                  # Display a helpful error the the terminal window.
                  puts "\nWARNING: #{@owner.class}##{@reflection.name.to_s}.build Will not create a has_many association between #{@owner.class} and #{reflection}."
                  puts "use #{@owner.class}##{@reflection.name.to_s}.create instead.\n"
                  obj = reflection.send(:new, args[0])
                  return obj
                end
                
                # Class#collections.create @record
                def create(*args)
                   reflection = @reflection.name.to_s.singularize.classify.constantize
                   obj = reflection.send(:create, args[0])
                   @owner.send(@reflection.name, send('<<',obj )) if obj.valid?
                   return obj
                end
                
                # Class#collections.clear @record
                def clear
                   self.each{| record | @owner.send(@reflection.name, send('delete',record))}
                end
                
                protected
                def create_delete_sql(self_class, other_class, record)
                  return "#{other_class}_type = '#{record.class.to_s}' AND #{other_class}_id = #{record.id} AND #{self_class}_id = " + "'#{@owner.id}'" +" AND #{self_class}_type ="+" '#{@owner.class.to_s}'"
                end
              end  
              
             class_eval <<-endofeval
               # collections=objects - replaces the collections content by deleting and adding objects as appropriate.
               def #{collection.to_s.pluralize}=(args)
                 self.#{collection.to_s.pluralize}.clear
                 args.each do | x |
                   self.#{collection.to_s.pluralize} << x
                 end
               end
               
               # collection_ids=[ids] - replaces the collections content by deleting and adding objects as appropriate.
               def #{collection.to_s.singularize}_ids=(args)
                 reflection = \"#{collection.to_s.singularize}\".classify.constantize
                 objs = []
                 args.each do | record | 
                   found = reflection.send(:find, record)
                   objs << found if found
                 end
                 self.#{collection.to_s.pluralize}= objs unless objs.empty?
               end
             endofeval
            end
          end
        end
      
        protected
        # Construct the SQL statement needed to bring back the correct association
        def create_sql_statements(options)
          
          # Why I am mixing single and double quotes in the finder_sql statement you ask?
          # Excellent question! The answer is when you use "double quotes" the string is 
          # interpolated immediately in current class.  When you use 'single quotes' the
          # string is interpolated by Rails in the context of a class instance.  
          # I use single quotes to get the correct id and double qoutes to get the correct
          # classname.
          sql =  " SELECT #{options[:association_table]}.* FROM #{options[:association_table]} "
          sql << " WHERE #{options[:association_table]}.id IN"
          sql << " (SELECT #{options[:association_column]}_id FROM #{options[:table_name]} WHERE #{options[:table_name]}.#{options[:association_column]}_type = " + "'#{options[:association_class]}'"
          sql << " AND #{options[:table_name]}.#{options[:class_column]}_id = " + '#{self.id}' 
          sql << " AND #{options[:table_name]}.#{options[:class_column]}_type = " + "'#{self.to_s}' )"
          # Only add this fragment if the table is STI.
          sql << " AND #{options[:association_table]}.type = " + "'#{options[:association_class]}'" if options[:association_class].columns.map{|x|x.name}.include?('type')
          sql
          counter_sql = sql.sub(/^SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
          return [counter_sql, sql]
        end   
        
        def create_collection_class(options)
          klass = Class.new ActiveRecord::Base do
            belongs_to options[:class_column].to_sym, :polymorphic=> true, :foreign_key=>'#{options[:class_column]}_id'
            belongs_to options[:association_column].to_sym, :polymorphic=> true, :foreign_key=>'#{options[:association_column]}_id'
            validates_presence_of "#{options[:class_column]}_id".to_sym, "#{options[:class_column]}_type".to_sym, "#{options[:association_column]}_id".to_sym, "#{options[:association_column]}_type".to_sym
          end
          klass_name = options[:table_name].to_s.singularize.classify
          const_set(klass_name, klass)
          klass.set_table_name options[:table_name]
          klass
        end    
      end
    end
  end
end

