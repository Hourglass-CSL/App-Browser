class MenusController < ApplicationController
  # La pantalla de Display es pública; este endpoint también debe serlo
  skip_before_action :authenticate_user!, only: :show

  # GET /menus/:model/:id/:which  -> JSON { url:, content_type: }
  def show
    model = params[:model].to_s.classify.safe_constantize
    return head :bad_request unless model

    record = model.find(params[:id])
    att_name = params[:which].to_s # "menu_file" o "menu_file_es"
    attachment = record.public_send(att_name)

    return head :no_content unless attachment.attached?

    blob = attachment.blob

    # 🔐 Evita links rotos: valida que el objeto exista en el service
    unless blob.service.exist?(blob.key)
      # opcional: limpia el blob colgado para forzar re-adjuntar luego
      attachment.purge_later
      return head :no_content
    end

    render json: {
      url: rails_blob_url(attachment, disposition: "inline"),
      content_type: blob.content_type
    }
  end

  private

  def allowed_models
    { "bar" => Bar, "restaurant" => Restaurant }
  end
end