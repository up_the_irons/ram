module ActiveRecord
  module Acts #:nodoc:
    module Subscribable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)  
      end
      
      module ClassMethods
        def acts_as_subscribable(options = {:subscribe_to=>[]})
          
          #the mixee is subscribed to other models
          is_a_subscriber unless options[:subscribe_to].empty?
          
          #the mixee has other classes subscribing to it
          is_subscribed_to if  options[:subscribe_to].empty?
          
          include ActiveRecord::Acts::Subscribable::InstanceMethods
          extend ActiveRecord::Acts::Subscribable::SingletonMethods          
        end
        
        def is_a_subscriber
          has_many :subscriptions, :foreign_key=>'subscriber_id', :conditions=>'subscriptions.subscriber_type = ' +"'#{self.class_name}'"
        end
        
        def is_subscribed_to
          
          # Why I am mixing single and double quotes in the finder_sql statement you ask?
          # Excellent question! The answer is when you use "double quotes" the string is 
          # interpolated immediately in current class.  When you use 'single quotes' the
          # string is interpolated by Rails in the context of a class instance.  
          # I use single quotes to get the correct id and double qoutes to get the correct
          # classname.

          has_many :subscribers,:class_name=>'Subscription', :finder_sql =>
                'SELECT subscriptions.* ' +
                'FROM subscriptions ' +
                'WHERE subscriptions.subscribed_to_id = #{self.id} AND subscriptions.subscribed_to_type =' + "'#{self.class_name}'" do
            
            #override the  << method so that it doesn't fuk up the association proxy.
            def <<(subscriber)
              return if @owner.subscribers.include?subscriber
              s = Subscription.create(
               :subscriber_id      => subscriber.id,
               :subscriber_type    => subscriber.class.class_name,
               :subscribed_to_id   => @owner.id,
               :subscribed_to_type => @owner.class.class_name	    
               )
               s.save!
            @owner.subscribers(true) 
           end
          
          end
        end
      end
      
      module SingletonMethods
        
      end
      
      module InstanceMethods
        def unsubscribe(remove_me)
          subscribers.map{|subscription| subscription.destroy if subscription.subscriber_id == remove_me.id}
          self.subscribers(true)
        end
        
        def unsubscribe_all
          subscribers.each{|subscription| subscription.destroy}
          self.subscribers(true)
        end
        
      end
      
    end
  end
end

