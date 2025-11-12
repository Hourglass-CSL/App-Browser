class BarsController < ApplicationController
  before_action :set_bar, only: %i[show edit update destroy purge_menu_file purge_menu_file_es]

  def index
    @bars = policy_scope(Bar)
              .select(:id, :bar_name, :day_of_week, :open_time, :closed_time,
                      :bar_type, :location, :ubicacion, :dress_code)
              .order(:bar_name)
              .load_async
    authorize Bar
  end

  def show
    authorize @bar 
  end

  def new
    @bar = Bar.new
    authorize @bar 
  end

  def edit
    authorize @bar  
  end


  def create
    @bar = Bar.new(bar_params.except(:stock_image_key_logo, :stock_image_key_menu_file, :stock_image_key_menu_file_es,:stock_image_keys_menu_file,
                               :stock_image_keys_menu_file_es))
    authorize @bar
    @bar.pending_logo_key = params[:stock_image_key_logo].presence

    if @bar.save
      attach_menu_from_stock(@bar, :menu_file,    params[:stock_image_key_menu_file])
      attach_menu_from_stock(@bar, :menu_file_es, params[:stock_image_key_menu_file_es])

      
      attach_menus_from_stock(@bar, :menu_file,    params[:stock_image_keys_menu_file])
      attach_menus_from_stock(@bar, :menu_file_es, params[:stock_image_keys_menu_file_es])
      
      AttachBarStockImagesJob
        .set(wait: 1.second)
        .perform_later(
          @bar.id,
          logo_key: params[:stock_image_key_logo].presence
        )

      redirect_to bars_path, notice: t("flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @bar
    @bar.pending_logo_key = params[:stock_image_key_logo].presence
    @bar.logo.purge_later if params.dig(:bar, :remove_logo) == "1"

    if @bar.update(bar_params.except(:stock_image_key_logo, :stock_image_key_menu_file, :stock_image_key_menu_file_es, :stock_image_keys_menu_file,
                                  :stock_image_keys_menu_file_es))
      attach_menu_from_stock(@bar, :menu_file,    params[:stock_image_key_menu_file])
      attach_menu_from_stock(@bar, :menu_file_es, params[:stock_image_key_menu_file_es])

      attach_menus_from_stock(@bar, :menu_file,    params[:stock_image_keys_menu_file])
      attach_menus_from_stock(@bar, :menu_file_es, params[:stock_image_keys_menu_file_es])

      AttachBarStockImagesJob
        .set(wait: 1.second)
        .perform_later(
          @bar.id,
          logo_key: params[:stock_image_key_logo].presence
        )

      redirect_to bars_path, notice: t("flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @bar 
    @bar.destroy
      respond_to do |format|
            format.turbo_stream 
     format.html { redirect_to bars_path, alert: t("flash.deleted") }
    end
  end

    def purge_menu_file
    authorize @bar , :update?
    att = @bar.menu_file.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: edit_bar_path(@bar),
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  def purge_menu_file_es
    authorize @bar, :update?
    att = @bar.menu_file_es.attachments.find(params[:attachment_id])
    att.purge
    redirect_back fallback_location: edit_bar_path(@bar),
                  notice: t("flash.removed", default: "Archivo eliminado.")
  end

  private

  def set_bar
    @bar = Bar.find(params[:id])
  end

  def bar_params
    params.require(:bar).permit(
      :bar_name,
      { day_of_week: [] },
      :open_time,
      :closed_time,
      :bar_type,
      :location,
      :dress_code,
      :logo,
      :remove_logo,
      { menu_file: [] },
      { menu_file_es: [] },
      :ubicacion,
      :vestimenta,
      :estilo,
      :stock_image_key_logo,
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
  end


  def attach_menus_from_stock(record, name, s3_keys)
    Array(s3_keys).reject(&:blank?).each do |key|
      attach_menu_from_stock(record, name, key)
    end
  end


 

end
