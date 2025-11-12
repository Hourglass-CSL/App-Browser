class SpecialsController < ApplicationController
  before_action :set_special, only: %i[ show edit update destroy ]

  def index
  
    @module_title = Rails.cache.fetch("module_title:v1", expires_in: 10.minutes) do
      ModuleTitle.select(:id, :title, :nombre).first_or_create
    end

    @specials = policy_scope(Special)
                  .select(:id, :special_name, :nombre, :day_of_week,
                          :open_time, :closed_time, :location, :ubicacion,
                          :description, :descripcion)
                  .order(:day_of_week) 
                  .load_async

    authorize Special
  end

  def show
    authorize @special
  end

  def new
    @special = Special.new
    authorize @special
  end

  def edit
    authorize @special
  end

  def create
    @special = Special.new(special_params.except(:stock_image_key_cover_image))
    authorize @special

    if @special.save
      if params[:stock_image_key_cover_image].present?
        AttachSpecialCoverImageJob
          .set(wait: 1.second)
          .perform_later(@special.id, cover_key: params[:stock_image_key_cover_image])
      end
      redirect_to specials_path, notice: t("flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end


  def update
    authorize @special

    if @special.update(special_params.except(:stock_image_key_cover_image))
      if params[:stock_image_key_cover_image].present?
        AttachSpecialCoverImageJob
          .set(wait: 1.second)
          .perform_later(@special.id, cover_key: params[:stock_image_key_cover_image])
      end
      redirect_to specials_path, notice: t("flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @special
    @special.destroy!
    respond_to do |format|
      format.turbo_stream  
      format.html { redirect_to specials_path, status: :see_other, notice: "Special was successfully destroyed." }   
    end
  end

 
  private
 
    def set_special
      @special = Special.find(params[:id])
    end
 
    def special_params
      params.require(:special).permit(:title, :special_name, :nombre, { day_of_week: [] }, :open_time, :closed_time, :location, :ubicacion, :description, :descripcion, :stock_image_key_cover_image, :cover_image)
    end
end
