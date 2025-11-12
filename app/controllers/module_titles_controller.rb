class ModuleTitlesController < ApplicationController
  before_action :set_module_title, only: %i[edit update]

  def edit
  end

  def update
    if @module_title.update(module_title_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to specials_path, notice: "Title updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_module_title
    @module_title = ModuleTitle.first_or_create
  end

  def module_title_params
    params.require(:module_title).permit(:title, :nombre)
  end
end
