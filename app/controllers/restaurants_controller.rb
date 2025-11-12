class RestaurantsController < ApplicationController
  before_action :set_restaurant, only: %i[show edit update destroy purge_menu_file purge_menu_file_es]

  def index
    @restaurants = policy_scope(Restaurant)
                     .select(:id, :restaurant_name, :meal_plan, :day_of_week,
                             :open_time, :closed_time, :restaurant_type,
                             :cuisine_type, :location, :ubicacion, :dress_code)
                     .order(:restaurant_name)
                     .load_async
    authorize Restaurant
  end

  def show
    authorize @restaurant
  end

  def new
    @restaurant = Restaurant.new
    authorize @restaurant
  end

  def edit
    authorize @restaurant
  end

  def create
    @restaurant = Restaurant.new(
      restaurant_params.except(:stock_image_key_logo,
                               :stock_image_key_menu_file,
                               :stock_image_key_menu_file_es,
                               :stock_image_keys_menu_file,
                               :stock_image_keys_menu_file_es)
    )
    authorize @restaurant
    @restaurant.pending_logo_key = params[:stock_image_key_logo].presence

    if @restaurant.save

      attach_menu_from_stock(@restaurant, :menu_file,    params[:stock_image_key_menu_file])
      attach_menu_from_stock(@restaurant, :menu_file_es, params[:stock_image_key_menu_file_es])


      attach_menus_from_stock(@restaurant, :menu_file,    params[:stock_image_keys_menu_file])
      attach_menus_from_stock(@restaurant, :menu_file_es, params[:stock_image_keys_menu_file_es])

      AttachRestaurantStockImagesJob
        .set(wait: 1.second)
        .perform_later(
          @restaurant.id,
          logo_key: params[:stock_image_key_logo].presence
        )

      redirect_to restaurants_path, notice: t("flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @restaurant
    @restaurant.pending_logo_key = params[:stock_image_key_logo].presence
    @restaurant.logo.purge_later if params.dig(:restaurant, :remove_logo) == "1"

    if @restaurant.update(
         restaurant_params.except(:stock_image_key_logo,
                                  :stock_image_key_menu_file,
                                  :stock_image_key_menu_file_es,
                                  :stock_image_keys_menu_file,
                                  :stock_image_keys_menu_file_es)
       )
   
      attach_menu_from_stock(@restaurant, :menu_file,    params[:stock_image_key_menu_file])
      attach_menu_from_stock(@restaurant, :menu_file_es, params[:stock_image_key_menu_file_es])

 
      attach_menus_from_stock(@restaurant, :menu_file,    params[:stock_image_keys_menu_file])
      attach_menus_from_stock(@restaurant, :menu_file_es, params[:stock_image_keys_menu_file_es])

      AttachRestaurantStockImagesJob
        .set(wait: 1.second)
        .perform_later(
          @restaurant.id,
          logo_key: params[:stock_image_key_logo].presence
        )

      redirect_to restaurants_path, notice: t("flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @restaurant
    @restaurant.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to restaurants_path, alert: t("alert.deleted") }
    end
  end

  def purge_menu_file
    authorize @restaurant, :update?
    att = @restaurant.menu_file.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: edit_restaurant_path(@restaurant),
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  def purge_menu_file_es
    authorize @restaurant, :update?
    att = @restaurant.menu_file_es.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: edit_restaurant_path(@restaurant),
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
  end

  def restaurant_params
    params.require(:restaurant).permit(
      :restaurant_name,
      { day_of_week: [] },
      :open_time,
      :closed_time,
      :restaurant_type,
      :location,
      :ubicacion,
      :dress_code,
      :meal_plan,
      :logo,
      :remove_logo,
      :cuisine_type,
      { menu_file: [] },
      { menu_file_es: [] },
      :stock_image_key_logo,
      :stock_image_key_menu_file,
      :stock_image_key_menu_file_es,
      { stock_image_keys_menu_file: [] },
      { stock_image_keys_menu_file_es: [] }
    )
  end


  def attach_menu_from_stock(record, name, s3_key)
    return if s3_key.blank?

    service = S3ImageService.new
    bucket  = service.instance_variable_get(:@bucket)
    client  = service.client

    filename     = File.basename(s3_key)
    content_type = client.head_object(bucket: bucket, key: s3_key).content_type || "application/octet-stream"

    Tempfile.create([File.basename(filename, ".*"), File.extname(filename)]) do |tmp|
      tmp.binmode
      client.get_object(bucket: bucket, key: s3_key, response_target: tmp.path)

      File.open(tmp.path, "rb") do |f|
        record.public_send(name).attach(
          io:          f,
          filename:    filename,
          content_type: content_type,
          metadata:    { source_s3_key: s3_key }
        )
      end
    end
  rescue Aws::S3::Errors::NoSuchKey
    Rails.logger.warn("[RestaurantsController] NoSuchKey for #{s3_key}")
  rescue => e
    Rails.logger.error("[RestaurantsController] attach_menu_from_stock #{e.class}: #{e.message}")
  end


  def attach_menus_from_stock(record, name, s3_keys)
    Array(s3_keys).reject(&:blank?).each do |key|
      attach_menu_from_stock(record, name, key)
    end
  end
end