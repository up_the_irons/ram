#--
# $Id: paging.rb 26 2006-07-12 05:07:25Z garry $
#
# Copyright (c) 2006 Garry C. Dolley
# All Rights Reserved.
#
# Modification and/or redistribution without prior written consent of Garry C.
# Dolley is strictly prohibited.
#
# Created: 04/08/2006
#
#++

# This module may be mixed-in any ActionController::Base class to give it the ability to paginate through a list of
# records at a higher level than normal controllers. Using the optional "paging_with_db" directive, the controller will
# have the ability to save the user's preference of "Rows / Page" between visits and on different computers.
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
# Use the ClassMethods#paging_with_db directive in your controller to auto-save the user's preference when they change 
# the "Rows / Page" value. See the documentation for that method and also note the required database table below.
#
# == Required module(s)
#   GBase
#
# == Required database table(s)
#
# The following table must exist in your default database before you can use the "paging_with_db" directive:
#
#   CREATE TABLE paging (
#     id int(11) NOT NULL auto_increment,
#     controller varchar(128) NOT NULL default '',
#     `action` varchar(128) NOT NULL default '',
#     num_per_page smallint(5) unsigned NOT NULL default '10',
#     PRIMARY KEY  (id),
#     UNIQUE KEY controller (controller,`action`)
#   ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
#
module Paging
  include GBase

  module ClassMethods

    # Add this directive to your controller and pass it the action(s) you want to be able to have the capability to
    # save the "Rows / Page" link that a user may click.
    def paging_with_db(*ids)
      s = GBase::ids_to_string(*ids)

      module_eval "before_filter :get_num_per_page, :only => [ #{s} ]"
      module_eval "after_filter :save_num_per_page, :only => [ #{s} ]"
    end
  end

  # Overrides ActionController::Paginate#paginate() to give ability to automatically pass the correct :per_page URL option
  # value.
  def paginate(collection_id, options={})
    if !options[:per_page].nil?
      params[:num_per_page] = options[:per_page].to_s
    else
      params[:num_per_page] = '10' if params[:num_per_page].nil?
    end

    super(collection_id, options.merge(:per_page => params[:num_per_page].to_i))
  end

  protected

  # Overrides ActionController::Base#default_url_options() so we can save the :page and :num_per_page variables between
  # requests. If you override this in your own controller or another module, you must call:
  #
  #    super(options).merge( { your_hash } )
  #
  # and not just return a hash. This is so your hash can be chained up the class/module hierarchy and we preserve all 
  # default URL parameters that came before you.
  def default_url_options(options)
    super(options).merge( params.nil? ? {} : { :page => params[:page], :num_per_page => params[:num_per_page] } )
  end

  private

  def save_num_per_page 
    if params[:new_num_per_page]
      p = Paging.find_by_controller_and_action(controller_name, action_name)

      if p
        p.update_attributes(:num_per_page => params[:num_per_page])
      else
        p = Paging.new(:controller => controller_name, :action => action_name, :num_per_page => params[:num_per_page])
        p.save
      end
    end
  end

  def get_num_per_page
    if params[:num_per_page].nil?
      p = Paging.find_by_controller_and_action(controller_name, action_name)
      
      params[:num_per_page] = p.num_per_page.to_s if p
    end
  end
end
