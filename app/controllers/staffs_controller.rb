class StaffsController < ApplicationController
  before_action :set_staff, only: %i[ show edit update destroy ]

  def index
    @staffs = policy_scope(Staff)
                .select(:id, :name, :position, :puesto, :bio, :descripcion)
                .order(:name)
                .load_async
    authorize Staff
  end

  def show
    authorize @staff
  end


  def new
    @staff = Staff.new
    authorize @staff
  end


  def edit
    authorize @staff
  end



  def create
    @staff = Staff.new(staff_params.except(:stock_image_key_profile_picture))
    authorize @staff

    if @staff.save
      # adjunta en background si vino un key
      if params[:stock_image_key_profile_picture].present?
        AttachStaffStockImageJob
          .set(wait: 1.second)
          .perform_later(
            @staff.id,
            profile_key: params[:stock_image_key_profile_picture]
          )
      end

      redirect_to staffs_path, notice: t("flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end


  def update
    authorize @staff

    if @staff.update(staff_params.except(:stock_image_key_profile_picture))
      if params[:stock_image_key_profile_picture].present?
        AttachStaffStockImageJob
          .set(wait: 1.second)
          .perform_later(
            @staff.id,
            profile_key: params[:stock_image_key_profile_picture]
          )
      end

      redirect_to staffs_path, notice: t("flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end



  def destroy
    authorize @staff
    @staff.destroy!

    respond_to do |format|
      format.turbo_stream  
      format.html { redirect_to staffs_url, notice: "staff deleted." }
    end
  end



  private


    def set_staff
      @staff = Staff.find(params[:id])
    end

  def staff_params
    params.require(:staff).permit(
      :name,
      :puesto,
      :position,
      :bio,
      :descripcion,
      :profile_picture,
      :stock_image_key_profile_picture
    )
  end
end
