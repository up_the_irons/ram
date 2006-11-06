#--
# $Id: paging.rb 26 2006-07-12 05:07:25Z garry $
#++

# This module may be mixed-in any ActionController::Base class to give it the ability to paginate through a list of
# records at a higher level than normal controllers. 
#
# Use the ActionController::Paginate#paginate method as usual (see Rails scaffold code for an example) and include the
# following partial in your view:
#
#   <%= render :partial => 'shared/paging', :locals => { :name => 'Tasks', :pages => @pages } %>
#
# This will output something like the following:
#
#   Tasks 1 - 10 of 15, pages 1 2                      Rows / Page: 10 20 40 80
#
# Modify the partial for a different look and feel.
#
# The following locals can be passed to the partial:
#
# * :name: The text for the noun before paging numbers ("1 - 10 of 15 ..." above) (_required_)
# * :pages: @pages instance variable above must be the Paginator that ActionController::Paginate#paginate returned (_required_)
# * :page_param: request parameter key that stores the current page number. Defaults to 'page'
# * :per_page_param: request parameter key that stores the current "Rows / Page" value. Defaults to 'num_per_page'
# * :per_page_array: defaults to [10,20,40,80]. Change this to have different "Rows / Page" links
#
# Use the ClassMethods#paging directive in your controller to save the user's preference when they change the
# "Rows / Page" value (stored in session). See the documentation for that method.
#
# == Required module(s)
#   GBase
#
module Paging
  include GBase

  module ClassMethods
    # Add this directive to your controller and pass it the action(s) you want to be able to have the capability to
    # save the "Rows / Page" link that a user may click.
    def paging(*ids)
      s = GBase::ids_to_string(*ids)

      module_eval "before_filter :get_paging_params, :only => [ #{s} ]"
      module_eval "after_filter  :set_paging_params, :only => [ #{s} ]"
    end
  end

  # Overrides ActionController::Paginate#paginate() to give ability to automatically pass the correct :per_page URL option
  # value.
  def paginate(collection_id, options = {})
    if !options[:per_page].nil?
      params[:num_per_page] = options[:per_page].to_s
    else
      params[:num_per_page] = '10' if params[:num_per_page].nil?
    end

    super(collection_id, options.merge(:per_page => params[:num_per_page].to_i))
  end

  private

  def set_paging_params 
    if params[:new_num_per_page]
      session["paging_#{controller_name}_#{action_name}"] = { :num_per_page => params[:num_per_page] }
    end
    if params[:new_page_num]
      session["paging_#{controller_name}_#{action_name}"] = { :page => params[:page] }
    end
  end

  def get_paging_params
    if params[:num_per_page].nil? && session["paging_#{controller_name}_#{action_name}"]
      params[:num_per_page] = session["paging_#{controller_name}_#{action_name}"][:num_per_page]
    end
    if params[:page].nil? && session["paging_#{controller_name}_#{action_name}"]
      params[:page] = session["paging_#{controller_name}_#{action_name}"][:page]
    end
  end
end
