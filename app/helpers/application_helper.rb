# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def display_flash_message
    flash_types = [:error, :warning, :notice ]
    flash_type = flash_types.detect{ |a| flash.keys.include?(a) }
    "<div id='page_flash' class='flash_%s'>%s</div>" % [flash_type.to_s, flash[flash_type]] if flash_type
  end
  
  def display_as asset
    case asset.content_type
      when 'image/jpeg','image/jpg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png'
        return "<img src='#{url_for :controller=>"asset", :action=>"show_inline", :id=>@asset.id }' />"
      when 'application/pdf'
        return "#{image_tag('/images/icons/page_white_acrobat.png')} #{link_to( asset.name, :controller=>'asset', :action=>'show',:id=>@asset.id)}"
      else
        return "#{link_to asset.name, :controller=>'asset', :action=>'show',:id=>@asset.id}"
    end
  end
  
  #used to create a category tree for use with the tree.js and tree.css files. This method is called recursivly
  def parse_tree(branches)
    code = ""
    branches.each do |b|
      link = link_to truncate(b[:name],25), :controller=>'category',:action=>'show',:id=>b[:id]
      if b[:children].size > 0
        code << "<li id=\"branch_#{b[:id]}\">#{link}\n\r" 
        code << "<ul>#{parse_tree(b[:children])}</ul></li>\n\r"
      end
      code << "<li id=\"branch_#{b[:id]}\">#{link}</li>\n\r" if b[:children].size == 0
    end
    code
  end
  
  def link_to_if_editable(name,options={},html_options=nil,*parameters_for_method_reference)
    if current_user.is_admin? || current_user.id == options[:id]
      url = link_to name,options,html_options,*parameters_for_method_reference
    end
  end

  def sort_arrow(sort)
    !sort.nil? ? sort == 'asc' ? '&uarr;' : '&darr;' : ''
  end

  def sort_header(opts = {})
    title = opts[:title]
    name  = opts[:name]
    
    url_options = { :sort => name, :sort_dir => @sort_dir[name] == 'asc' ? 'desc' : 'asc' }
    url_options.merge!(opts[:url]) if opts[:url]

    link_to_remote(title, :url => url_options) + sort_arrow(@sort_dir[name])
  end 
end
