module Sortable
  include GBase

  module ClassMethods
    def sortable(*ids)
      s = GBase::ids_to_string(*ids)

      module_eval "before_filter :set_sort_params, :only => [ #{s} ]"
    end
  end

  protected

  def default_url_options(options)
    super(options).merge( params.nil? ? {} : { :sort => params[:sort], :sort_dir => params[:sort_dir] } )
  end

  private

  def set_sort_params
    @sort_dir = { params[:sort] => params[:sort_dir] }
    @order = params[:sort] + " " + params[:sort_dir].to_s if !params[:sort].nil?
  end
end
