class ActivitiesController < ApplicationController
  before_action :set_activity, only: %i[show edit update destroy]

  def index
    # columnas que SÍ usas en la vista
    scope = policy_scope(Activity)
              .select(:id, :title, :nombre, :day_of_week, :open_time, :closed_time,
                      :location, :ubicacion, :description, :descripcion)
              .order(Arel.sql("open_time::time"))

    @activities = scope.load_async
    authorize Activity
  end

  def show
    authorize @activity 
  end

  def new
    @activity = Activity.new
    authorize @activity 
  end

  def create
    @activity = Activity.new(activity_params.except(:stock_image_key_cover_image))
    authorize @activity

    if @activity.save
      if params[:stock_image_key_cover_image].present?
        AttachActivityCoverImageJob
          .set(wait: 1.second)
          .perform_later(@activity.id, cover_key: params[:stock_image_key_cover_image])
      end
      redirect_to activities_path, notice: t("flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @activity 
  end

  def update
    authorize @activity

    if @activity.update(activity_params.except(:stock_image_key_cover_image))
      if params[:stock_image_key_cover_image].present?
        AttachActivityCoverImageJob
          .set(wait: 1.second)
          .perform_later(@activity.id, cover_key: params[:stock_image_key_cover_image])
      end
      redirect_to activities_path, notice: t("flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
  authorize @activity 
    @activity.destroy
    respond_to do |format|
      format.turbo_stream   
      format.html { redirect_to activities_url, alert: t("flash.deleted") }
    end
  end


  private

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(
      :title,
      :nombre,
      :location,
      :ubicacion,
      :description,
      :descripcion,
      { day_of_week: [] },
      :open_time,
      :closed_time,
      :stock_image_key_cover_image,
      :cover_image
    )
  end
end
