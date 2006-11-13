require_dependency 'collection_methods'

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include CollectionMethods
  include Sortable
  include Paging
  
  def paginate_collection(collection, options = {})
    default_options = {:per_page => 10, :page => 1}
    options = default_options.merge options

    options[:page]     ||= default_options[:page]
    options[:per_page] ||= default_options[:per_page]

    pages = Paginator.new self, collection.size, options[:per_page].to_i, options[:page].to_i
    first = pages.current.offset
    last = [first + options[:per_page].to_i, collection.size].min
    slice = collection[first...last]
    return [pages, slice]
  end
  
end
