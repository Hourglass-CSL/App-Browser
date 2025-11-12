module ApplicationHelper
  def qr_code_tag
    if @setting&.qr_code&.attached?
      image_tag(@setting.qr_code, class: "w-32 h-auto")
    else
      content_tag(:p, "QR code not uploaded.", class: "text-gray-400")
    end
  end

 
  def link_to_with_locale(name = nil, options = nil, html_options = nil, &block)
    if options.is_a?(Hash)
      options = options.merge(locale: I18n.locale)
    end
    link_to(name, options, html_options, &block)
  end
 

end