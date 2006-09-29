module Unchangeable
  def validates_unchangeable(*attr_names)
    configuration = { :message => "can't be changed" }
    configuration.merge!(attr_names.pop) if attr_names.last.is_a?(Hash)
    send( validation_method(:update) ) do |record|
      #unless configuration[:if] and not evaluate_condition(configuration[:if], record)
      unless !configuration[:if].nil? and not configuration[:if].call(record)
        #breakpoint
        previous = self.find record.id
        attr_names.each do |attr_name|
          record.errors.add( attr_name, configuration[:message] ) if record.respond_to?(attr_name) and previous.send(attr_name) != record.send(attr_name)
          #breakpoint
          # replace the 'and' above with a double ampersand 
        end
      end
    end
  end
end