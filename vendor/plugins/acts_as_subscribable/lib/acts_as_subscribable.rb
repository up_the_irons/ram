#--
# $Id$
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
 #   has_a_collection :of =>%w(articles authors), :for => ["readers"]
 # end
 # 
 # Allows only the Blog class to collect to the Feed class.
 # class Feed
 #   has_a_collection :for => ["blogs"]
 # end

module ActiveRecord
  module Acts #:nodoc:
    module Subscribable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)  
      end
      
      module ClassMethods

        def acts_as_subscribable(opts = {})
          options = {:of => [], :for => []}.merge(opts)
          # The mixee collects other models
          has_a_collection_of(options) unless options[:of].empty?
          
          # The mixee is collected by other models
          is_collected_by(options) unless options[:for].empty?
          
          include ActiveRecord::Acts::Subscribable::InstanceMethods
          extend ActiveRecord::Acts::Subscribable::SingletonMethods          
        end
        
        # For example @novel has a collection of chapters
        def has_a_collection_of(options)
          self.module_eval do
            
            options[:of].each do | collection |
              collected_class = collection.to_s.singularize.classify.constantize
              collections_table = collected_class.class_name.tableize
              counter_sql, sql = create_sql_statements({:collection_table => collections_table, :collection_class => collected_class,:collector? => true})
              
              # TODO need to add these methods                
              # collection=objects - replaces the collections content by deleting and adding objects as appropriate.
              
              # Dynamically create a has_many association.  
              has_many collection.to_s.pluralize.to_sym, :finder_sql => sql, :counter_sql => counter_sql do
                def <<(subscription)
                  # Ensure unique records of the right class
                  return unless @owner.respond_to?subscription.class.to_s.tableize.to_sym
                  return unless @owner.send(subscription.class.to_s.tableize.to_sym, true).map{|x| return false if x.id == subscription.id}
                  s = Subscription.create(
                    :subscriber_id      => @owner.id,
                    :subscriber_type    => @owner.class.to_s,
                    :subscribed_to_id   => subscription.id,
                    :subscribed_to_type => subscription.class.to_s
                  )
                  # Force the reload of the association
                  @owner.send(subscription.class.to_s.tableize.to_sym, true)
                end  
                 
                def delete(subscription)
                  s = Subscription.find :first, :conditions =>"subscribed_to_type = \'#{subscription.class.to_s}\' AND subscribed_to_id = #{subscription.id} AND subscriber_id = " + "'#{@owner.id}'" +" AND subscriber_type ="+" '#{@owner.class.to_s}'"
                  return false unless s
                  return false unless s.destroy
                  @owner.send(subscription.class.to_s.tableize.to_sym, true)
                end
                
                def build(*args)
                  reflection = @reflection.name.to_s.singularize.classify.constantize
                  # Display a helpful error the the terminal window.
                  puts "\n WARNING: #{@owner.class}##{@reflection.name.to_s}.build Will not create a has_many association between #{@owner.class} and #{reflection}."
                  puts "use #{@owner.class}##{@reflection.name.to_s}.create instead.\n"
                  obj = reflection.send(:new, args[0])
                  return obj
                end
                
                def create(*args)
                  reflection = @reflection.name.to_s.singularize.classify.constantize
                  obj = reflection.send(:create, args[0])
                  @owner.send(@reflection.name, send('<<',obj )) if obj.valid?
                  return obj
                end
                
                def clear
                  self.each{| record | @owner.send(@reflection.name, send('delete',record))}
                end
              end  
            end
          end
        end
        
        # For example a feed is collected by user i.e. @user.feeds
        def is_collected_by(options)
          self.module_eval do
            # Dynamically create a has_many association.
            options[:for].each do | collector |
               collector_class = collector.to_s.singularize.classify.constantize
               collectors_table = collector_class.class_name.tableize
               
               counter_sql, sql = create_sql_statements({:collection_table => collectors_table, :collection_class => collector_class, :collector? => false})
               has_many collector.to_s.pluralize.to_sym, :finder_sql => sql, :counter_sql => counter_sql do
                 def <<(subscriber)
                   # Ensure unique records of the right class
                   return unless @owner.respond_to?subscriber.class.to_s.tableize.to_sym
                   return unless @owner.send(subscriber.class.to_s.tableize.to_sym, true).map{|x| return false if x.id == subscriber.id}
                   s = Subscription.create(
                     :subscriber_id      => subscriber.id,
                     :subscriber_type    => subscriber.class.to_s,
                     :subscribed_to_id   => @owner.id,
                     :subscribed_to_type => @owner.class.to_s
                   )
                   # Force the reload of the association
                   @owner.send(subscriber.class.to_s.tableize.to_sym, true)
                 end
                 
                 def delete(subscription)
                   s = Subscription.find :first, :conditions =>"subscriber_type = \'#{subscription.class.to_s}\' AND subscriber_id = #{subscription.id} AND subscribed_to_id = " + "'#{@owner.id}'" +" AND subscribed_to_type ="+" '#{@owner.class.to_s}'"
                   return false unless s
                   return false unless s.destroy
                   @owner.send(subscription.class.to_s.tableize.to_sym, true)
                 end
                 
                 def create(*args)
                   reflection = @reflection.name.to_s.singularize.classify.constantize
                   obj = reflection.send(:create, args[0])
                   @owner.send(@reflection.name, send('<<',obj )) if obj.valid?
                   return obj
                 end
                 
                 def clear
                   self.each{| record | @owner.send(@reflection.name, send('delete',record))}
                 end
               end  
            end
          end
        end
      
        protected
       
        # Construct the SQL statement needed to bring back the correct association
        def create_sql_statements(opts)
          options = {:collection_table => nil, :collection_class => nil, :collector? => nil}.merge(opts)
          if options[:collector?]
            self_class = "subscriber" 
            other_class = "subscribed_to"
          else
            self_class = "subscribed_to" 
            other_class = "subscriber"            
          end
          # Why I am mixing single and double quotes in the finder_sql statement you ask?
          # Excellent question! The answer is when you use "double quotes" the string is 
          # interpolated immediately in current class.  When you use 'single quotes' the
          # string is interpolated by Rails in the context of a class instance.  
          # I use single quotes to get the correct id and double qoutes to get the correct
          # classname.
          sql =  " SELECT #{options[:collection_table]}.* FROM #{options[:collection_table]} "
          sql << " WHERE #{options[:collection_table]}.id IN"
          sql << " (SELECT #{other_class}_id FROM subscriptions WHERE subscriptions.#{other_class}_type = " + "'#{options[:collection_class]}'"
          sql << " AND subscriptions.#{self_class}_id = " + '#{self.id}' 
          sql << " AND subscriptions.#{self_class}_type = " + "'#{self.to_s}' )"
          # Only add this fragment if the table is STI.
          sql << " AND #{options[:collection_table]}.type = " + "'#{options[:collection_class]}'" if options[:collection_class].columns.map{|x|x.name}.include?('type')
          sql
          counter_sql = sql.sub(/^SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
          return [counter_sql, sql]
        end
      
      end
      
      module SingletonMethods
      end
      
      module InstanceMethods

      end
      
    end
  end
end

