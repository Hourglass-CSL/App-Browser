 
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Scopes (index)
  class Scope
    attr_reader :user, :scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # por defecto todos ven el index; ajusta según tu caso
    def resolve
      scope.all
    end
  end

  # Lectura: todos pueden ver (ajusta si necesitas restringir list/show)
  def index?  = true
  def show?   = true

  # Crear/editar/borrar:
  def create? = user&.admin? || user&.user?
  def new?    = create?

  def update? = user&.admin? || user&.user?
  def edit?   = update?

  def destroy? = user&.admin?

  # Acceso a páginas completas de admin
  def admin_only? = user&.admin?
end