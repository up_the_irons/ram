# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def display_flash_message

    flash_types = [:error, :warning, :notice ]
    flash_type = flash_types.detect{ |a| flash.keys.include?(a) }
    
    "<div id='page_flash' class='flash_%s'>%s</div>" % [flash_type.to_s, flash[flash_type]] if flash_type 
  end
  
  
  def grail_notify(opts={})
    props = {:skin=>nil,:subject=>nil, :body=>nil,:type=>nil}.merge(opts)
    out =  "<script type='text/javascript'>\n"
    out << "/* <![CDATA[ */\n"
    out << "Loader.addOnLoad(function(){grail.notify({type:\"#{CGI.escapeHTML props[:type]}\", subject:\"#{CGI.escapeHTML props[:subject]}\",skin:\"#{CGI.escapeHTML props[:skin]}\", body:\"#{CGI.escapeHTML props[:body]}\"})})\r"
    #out << "Loader.addOnLoad(function(){grail.notify({subject:\"#{CGI.escapeHTML props[:subject]}\",skin:\"#{CGI.escapeHTML props[:skin]}\", body:\"#{CGI.escapeHTML props[:body]}\"})})\r"
    out << "/* ]]> */"
    out << "</script>"
  end
  
  
  def display_as(asset, opts={:size=>"medium"})
    case asset.content_type
      when 'image/jpeg','image/jpg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png'
        unless asset.thumbnail_size(opts[:size]).nil?
          return "#{image_tag(url_for(:controller=>'asset', :action=>'show_inline', :id=>asset.thumbnail_size(opts[:size]))) }"
        else
          return "#{image_tag(url_for(:controller=>'asset', :action=>'show_inline', :id=>asset.id)) }"
        end
      when 'application/pdf'
        return "#{image_tag('/images/icons/page_white_acrobat.png')} #{link_to( asset.name, :controller=>'asset', :action=>'show',:id=>asset.id)}"
      else
        return "#{link_to(image_tag('/images/icons/page_white.png'), :controller=>'asset', :action=>'show',:id=>asset.id)}"
    end
  end
  
  
  #used to create a category tree for use with the tree.js and tree.css files. This method is called recursivly
  def parse_tree(branches)
    code = ""
    branches.each do |b|
      link = link_to truncate(b[:name],25),:controller=>'category', :action=>'show',:id=>b[:id]
      if b[:children].size > 0
        code << "<li id=\"branch_#{b[:id]}\">#{link}\n\r" 
        code << "<ul>#{parse_tree(b[:children])}</ul></li>\n\r"
      end
      code << "<li id=\"branch_#{b[:id]}\">#{link}</li>\n\r" if b[:children].size == 0
    end
    code
  end
  
  def parse_selectable_tree(branches)
     code = ""
     branches.each do |b|
       #used to toggle on and off the checkbox graphic
       onclick_method = %{if(!$('category_#{b[:id]}').checked){$('tick_#{b[:id]}').show()}else{$('tick_#{b[:id]}').hide();}}
       
       link = %{<input type='checkbox' style="display:none;" name="group[category_ids][]" value="#{b[:id]}" id="category_#{b[:id]}" />} 
       link << image_tag('icons/tick.png',{:style=>"display:none",:id=>"tick_#{b[:id]}"})
       link << link_to(truncate(b[:name],25),"#checkbox_#{b[:id]}",{:onclick=>onclick_method})
       if b[:children].size > 0
         code << "<li id=\"selectable_branch_#{b[:id]}\">#{link}\n\r" 
         code << "<ul>#{parse_selectable_tree(b[:children])}</ul></li>\n\r"
       end
       code << "<li id=\"selectable_branch_#{b[:id]}\">#{link}</li>\n\r" if b[:children].size == 0
     end
     code
  end
  
  def admin_only_content
    yield if current_user.is_admin?
  end

  
  def link_to_if_editable(name,options={},html_options=nil,*parameters_for_method_reference)
    if current_user.is_admin?
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
