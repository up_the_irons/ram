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
 # The advantage of has_a_collection over the :through option in has_many is that the associations can be polymorphic on both ends.
 # In a typical polymorphic has_many assocation at least one class still needs to use a "belongs_to" association. 
 # The collection module transparently handles the implicit joins between the two models.
 # The syntax is very readable for example, for class User 'has a collection of blogs' would be written:
 # has_a_collection :of =>["blogs"] 
 #
 # == Example implementations of has_a_collection
 # Creates @reader.articles and @reader.comments
 # class Reader < ActiveRecord::Base
 #   has_a_collection :of => ["blogs","comments"]
 # end
 # 
 # Creates @blogs.articles, @blogs.authors and @reader.blogs
 # Allows only the Reader class to collect to the Blog class.
 # class Blog < ActiveRecord::Base
 #   has_a_collection :of =>%w(articles authors)
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
        def has_a_collection(opts = {})
          options = {:of => []}.merge(opts)
          create_associations(options[:of],"subscriber","subscribed_to") unless options[:of].empty?
        end
        
        def is_collected(opts ={})
          options = {:by => []}.merge(opts)
          create_associations(options[:by],"subscribed_to","subscriber") unless options[:by].empty?
        end

        # For example novel has a collection of chapters i.e. @novel.chapters
        def create_associations(options,self_class,other_class)
          module_eval do
            options.each do | collection |
              counter_sql, sql = create_sql_statements({
                                                        :collection_table => collection.to_s.singularize.classify.constantize.class_name.tableize, 
                                                        :collection_class => collection.to_s.singularize.classify.constantize,
                                                        :self_class => self_class, 
                                                        :other_class=> other_class
                                                        })
              
              # Dynamically create a has_many association.  
              has_many collection.to_s.pluralize.to_sym, :finder_sql => sql, :counter_sql => counter_sql do
                class_eval <<-endofeval
                  # Class#collections << @record
                  def <<(subscription)
                    # Ensure unique records of the right class
                    return unless @owner.respond_to?subscription.class.to_s.tableize.to_sym
                    return unless @owner.send(subscription.class.to_s.tableize.to_sym, true).map{|x| return false if x.id == subscription.id}
                    s = Subscription.create(
                      :#{self_class}_id    => @owner.id,
                      :#{self_class}_type  => @owner.class.to_s,
                      :#{other_class}_id   => subscription.id,
                      :#{other_class}_type => subscription.class.to_s
                    )
                    # Force the reload of the association
                    @owner.send(subscription.class.to_s.tableize.to_sym, true)
                  end
                  
                  # Class#collections.delete @record
                  def delete(subscription)
                    subscription.each{| x | @owner.send(@reflection.name, send('delete',subscription[x] ))} if subscription.is_a?(Array)
                    s = Subscription.find :first, :conditions =>create_delete_sql( '#{self_class}', '#{other_class}', subscription )
                    return false unless s
                    return false unless s.destroy
                    @owner.send(subscription.class.to_s.tableize.to_sym, true)
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
                def create_delete_sql(self_class, other_class, subscription)
                  return "#{other_class}_type = '#{subscription.class.to_s}' AND #{other_class}_id = #{subscription.id} AND #{self_class}_id = " + "'#{@owner.id}'" +" AND #{self_class}_type ="+" '#{@owner.class.to_s}'"
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
        def create_sql_statements(opts ={})
          options = {:collection_table => nil, :collection_class => nil, :self_class => nil, :other_class => nil}.merge(opts)
          
          # Why I am mixing single and double quotes in the finder_sql statement you ask?
          # Excellent question! The answer is when you use "double quotes" the string is 
          # interpolated immediately in current class.  When you use 'single quotes' the
          # string is interpolated by Rails in the context of a class instance.  
          # I use single quotes to get the correct id and double qoutes to get the correct
          # classname.
          sql =  " SELECT #{options[:collection_table]}.* FROM #{options[:collection_table]} "
          sql << " WHERE #{options[:collection_table]}.id IN"
          sql << " (SELECT #{options[:other_class]}_id FROM subscriptions WHERE subscriptions.#{options[:other_class]}_type = " + "'#{options[:collection_class]}'"
          sql << " AND subscriptions.#{options[:self_class]}_id = " + '#{self.id}' 
          sql << " AND subscriptions.#{options[:self_class]}_type = " + "'#{self.to_s}' )"
          # Only add this fragment if the table is STI.
          sql << " AND #{options[:collection_table]}.type = " + "'#{options[:collection_class]}'" if options[:collection_class].columns.map{|x|x.name}.include?('type')
          sql
          counter_sql = sql.sub(/^SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
          return [counter_sql, sql]
        end       
      end
    end
  end
end

