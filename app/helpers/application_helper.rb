# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def display_flash_message
    flash_types = [:error, :warning, :notice ]
    flash_type = flash_types.detect{ |a| flash.keys.include?(a) }
    "<div class='flash_%s'>%s</div>" % [flash_type.to_s, flash[flash_type]] if flash_type
  end
  
  def display_as asset
    case asset.content_type
      when 'image/jpeg','image/jpg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png'
        return "<img src='#{url_for :controller=>"asset", :action=>"show", :id=>@asset.id }' />"
      when 'application/pdf'
        return "#{image_tag('/images/icons/page_white_acrobat.png')} #{link_to( asset.name, :controller=>'asset', :action=>'show',:id=>@asset.id)}"
      else
        return "#{link_to asset.name, :controller=>'asset', :action=>'show',:id=>@asset.id}"
    end
   
      
    #if @@content_types.include?(asset.content_type)
    #  return "<img src='#{url_for :controller=>"asset", :action=>"show", :id=>@asset.id }' />"
    #else
    #  return "#{link_to asset.name, :controller=>'asset', :action=>'show',:id=>@asset.id}"
    #end
  end
  
end
