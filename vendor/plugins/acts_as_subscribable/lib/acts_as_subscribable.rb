#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

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
          
          has_many :subscriptions, :foreign_key => 'subscriber_id', :conditions => 'subscriptions.subscriber_type = ' +"'#{self.class_name}'" do
            # Override the  << method so that it doesn't fuk up the association proxy.
            def <<(subscription)
              return unless @owner.subscriptions.map{|s| return false if s.subscribed_to_id == subscription.id && s.subscribed_to_type == subscription.class.class_name}
              s = Subscription.create(
                :subscriber_id      => @owner.id,
                :subscriber_type    => @owner.class.class_name,
                :subscribed_to_id   => subscription.id,
                :subscribed_to_type => subscription.class.class_name
              )
              @owner.subscriptions(true)
            end
            
            # @reader.subscriptions.include?(@magazine) #=> true / false
            def include?(subscription)
              @owner.subscriptions.map{|s| return true if s.subscribed_to_id == subscription.id && s.subscribed_to_type == subscription.class.class_name}
              return false
            end 
          end
        
          # Dynamically create methods which map to the specific types of subscriptions          
          self.module_eval do
            options[:subscribe_to].each do | assoc |
              define_method(assoc.to_s.pluralize) do
                klass = assoc.to_s.singularize.classify
                puts klass
                objects = []
                subscriptions.map{|s| objects << Klass.find(s.subscribed_to_id) s.subscribed_to_type == klass.to_s}
                return objects
              end
            end
          end
          breakpoint
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
                'WHERE subscriptions.subscribed_to_id = #{self.id} AND subscriptions.subscribed_to_type =' + "'#{self.class_name}'" do
            
            # Override the  << method so that it doesn't fuk up the association proxy.
            def <<(subscriber)
              return unless @owner.subscribers.map{|s| return false if s.subscriber_id == subscriber.id && s.subscriber_type == subscriber.class.class_name}
              s = Subscription.create(
               :subscriber_id      => subscriber.id,
               :subscriber_type    => subscriber.class.class_name,
               :subscribed_to_id   => @owner.id,
               :subscribed_to_type => @owner.class.class_name	    
               )
            @owner.subscribers(true) 
           end
           
           # @feed.subscribers.include?(@reader) #=> true / false
           def include?(subscriber)
             @owner.subscribers.map{|s| return true if s.subscriber_id == subscriber.id && s.subscriber_type == subscriber.class.class_name}
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

