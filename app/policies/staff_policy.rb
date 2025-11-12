class StaffPolicy < ApplicationPolicy
  # ✅ Todos los roles (incluye reader) pueden listar y ver
  def index?  = true
  def show?   = true

  # ✋ Crear / Editar solo admin y user
  def create? = user&.admin? || user&.user?
  def new?    = create?

  def update? = user&.admin? || user&.user?
  def edit?   = update?

  # 🗑️ Borrar solo admin (opcional)
  def destroy? = user&.admin? || user&.user?

  # Scope (si no filtras por rol, deja all)
  class Scope < Scope
    def resolve = scope.all
  end
end