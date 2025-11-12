class Admin::UsersController < Admin::BaseController
  def index
    @users = User
               .select(:id, :name, :email, :role, :created_at, :last_sign_in_at)
               .order(:id)
               .load_async
  end
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: "Usuario creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "Usuario actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

def destroy
  @user = User.find(params[:id])

  if @user == current_user
    redirect_to admin_users_path, alert: "No puedes eliminar tu propia cuenta."
    return
  end

  if @user.admin? && User.admin.count == 1
    redirect_to admin_users_path, alert: "No puedes eliminar al último administrador."
    return
  end

  @user.destroy
  redirect_to admin_users_path, alert: "Usuario eliminado."
end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end
