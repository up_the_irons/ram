#--
# $Id$
#
 # Copyright (c) 2006 Mark Daggett
 #
 # This file is part of RAM (Ruby Asset Manager) 
 # 
 # Released under the MIT / X11 License.  See LICENSE file for details.
 # ++
 
 
 # == Acts As Subscribable
 # Acts as subscribable allows you to extend a model to afford other models to subscribe to it.
 # The advantage of acts_as_subscribable over the :through option in has_many is that the associations can be polymorphic on both ends.
 # The subscribable module transparently handles the implicit joins between the two models.
 #
 # == Example implementations of acts_as_subscribable
 # Creates @reader.blogs
 # class Reader
 #   acts_as_subscribable :subscribe_to => ["blogs"]
 # end
 # 
 # Creates @blogs.feeds, @blogs.newspapers
 # Allows only the Reader class to subscribe to the Blog class.
 # class Blogs
 #   acts_as_subscribable :subscribe_to => ["feeds","newspapers"], :allow_subscriptions_from => ["readers"]
 # end
 # 
 # Allows only the Blog class to subscribe to the Feed class.
 # class Feed
 #   acts_as_subscribable :allow_subscriptions_from => ["blogs"]
 # end

module ActiveRecord
  module Acts #:nodoc:
    module Subscribable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)  
      end
      
      module ClassMethods

        def acts_as_subscribable(options = {:subscribe_to=>[]})
                    
          # The mixee is subscribed to other models
          is_a_subscriber(options) unless options[:subscribe_to].empty?
          
          # The mixee has other classes subscribing to it
          is_subscribed_to(options) if options[:subscribe_to].empty?
          
          include ActiveRecord::Acts::Subscribable::InstanceMethods
          extend ActiveRecord::Acts::Subscribable::SingletonMethods          
        end
        
        # For example a User is_a_subscriber to Feeds
        def is_a_subscriber(options)
          self.module_eval do
            # Dynamically create a has_many association.
            options[:subscribe_to].each do | subscribable |
               subscribed_to_class = subscribable.to_s.singularize.classify.constantize
               subscribed_to_table = subscribed_to_class.class_name.tableize
               subscriber_table = self.class_name.tableize
               
               # Why I am mixing single and double quotes in the finder_sql statement you ask?
               # Excellent question! The answer is when you use "double quotes" the string is 
               # interpolated immediately in current class.  When you use 'single quotes' the
               # string is interpolated by Rails in the context of a class instance.  
               # I use single quotes to get the correct id and double qoutes to get the correct
               # classname.
               
               # Construct the SQL statement needed to bring back the correct association
               sql =  " SELECT #{subscribed_to_table}.* FROM #{subscribed_to_table} "
               sql << " WHERE #{subscribed_to_table}.id IN"
               sql << " (SELECT subscribed_to_id FROM subscriptions WHERE subscriptions.subscribed_to_type = " + "'#{subscribed_to_class}'"
               sql << " AND subscriptions.subscriber_id = " + '#{self.id}' 
               sql << " AND subscriptions.subscriber_type = " + "'#{self.to_s}' )"
               # Only add this fragment if the table is STI.
               sql << " AND #{subscribed_to_table}.type = " + "'#{subscribed_to_class}'" if subscribed_to_class.columns.map{|x|x.name}.include?('type')
               
               counter_sql = sql.sub(/^SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }

               has_many subscribable.to_s.pluralize.to_sym, :finder_sql => sql, :counter_sql => counter_sql do
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
                 
                 # TODO remove the subscription but not the object because acts_as_subscribable doesn't handle 'belongs_to' associations
                 def delete(subscription)
                 end
              end  
            end
          end
          
          
          has_many :subscriptions, :foreign_key => 'subscriber_id', :conditions => 'subscriptions.subscriber_type = ' +"'#{self.to_s}'" do
            # Override the  << method so that it doesn't fuk up the association proxy.
            def <<(subscription)
              return unless @owner.subscriptions.map{|s| return false if s.subscribed_to_id == subscription.id && s.subscribed_to_type == subscription.class.to_s}
              s = Subscription.create(
                :subscriber_id      => @owner.id,
                :subscriber_type    => @owner.class.to_s,
                :subscribed_to_id   => subscription.id,
                :subscribed_to_type => subscription.class.to_s
              )
              @owner.subscriptions(true)
            end
            
            # @reader.subscriptions.include?(@magazine) #=> true / false
            def include?(subscription)
              @owner.subscriptions.map{|s| return true if s.subscribed_to_id == subscription.id && s.subscribed_to_type == subscription.class.to_s}
              return false
            end 
          end
        
          # Dynamically create methods which map to the specific types of subscriptions    
          # TODO see if you can replace this with an alias method to the has_many      
          # self.module_eval do
          #   options[:subscribe_to].each do | assoc |
          #     # alias_method assoc.to_s.pluralize.to_sym, :subscriptions
          #     define_method(assoc.to_s.pluralize) do
          #        klass = assoc.to_s.singularize.classify.constantize
          #        objects = []
          #        subscriptions.map{|s| objects << klass.send(:find, s.subscribed_to_id) if s.subscribed_to_type == klass.to_s}
          #        return objects
          #     end
          #   end
          # end
        end
        
        # For example a Feed is subscribed_to by A User.
        def is_subscribed_to(options)
          
          # Why I am mixing single and double quotes in the finder_sql statement you ask?
          # Excellent question! The answer is when you use "double quotes" the string is 
          # interpolated immediately in current class.  When you use 'single quotes' the
          # string is interpolated by Rails in the context of a class instance.  
          # I use single quotes to get the correct id and double qoutes to get the correct
          # classname.

          has_many :subscribers, :class_name => 'Subscription', :finder_sql =>
                'SELECT subscriptions.* ' +
                'FROM subscriptions ' +
                'WHERE subscriptions.subscribed_to_id = #{self.id} AND subscriptions.subscribed_to_type =' + "'#{self.to_s}'" do
            
            # Override the  << method so that it doesn't fuk up the association proxy.
            def <<(subscriber)
              return unless @owner.subscribers.map{|s| return false if s.subscriber_id == subscriber.id && s.subscriber_type == subscriber.class.to_s}
              s = Subscription.create(
               :subscriber_id      => subscriber.id,
               :subscriber_type    => subscriber.class.to_s,
               :subscribed_to_id   => @owner.id,
               :subscribed_to_type => @owner.class.to_s      
               )
            @owner.subscribers(true) 
           end
           
           # @feed.subscribers.include?(@reader) #=> true / false
           def include?(subscriber)
             @owner.subscribers.map{|s| return true if s.subscriber_id == subscriber.id && s.subscriber_type == subscriber.class.to_s}
             return false
           end
           
           # @feed.subscribers.unsubscribe << @feed.subscribers[0]
           def unsubscribe(remove_me)
             @owner.subscribers.map{|subscription| subscription.destroy if subscription.subscriber_id == remove_me.id}
             @owner.subscribers(true)
           end

           # @feed.unsubscribe_all
           def unsubscribe_all
             @owner.subscribers.each{|subscription| subscription.destroy}
             @owner.subscribers(true)
           end
          
          end
        end
      end
      
      module SingletonMethods
      end
      
      module InstanceMethods

      end
      
    end
  end
end

