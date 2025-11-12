class StockImagesController < ApplicationController

  def stock_images
    service = S3ImageService.new
    folders = params[:folder].to_s.split(",")
    @images = folders.flat_map do |prefix|
      service.list_images(prefix.strip)
    end

    render partial: "shared/stock_gallery", locals: { images: @images }
  end

    def fetch
    key = params[:key].to_s
    return head :bad_request if key.blank?

    service = S3ImageService.new
    url = service.image_url(key) # genera una presignada nueva (https)

    render json: { url: url }
  end
  
end