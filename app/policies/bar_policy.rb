class BarPolicy < ApplicationPolicy
  
  def index?  = true
  def show?   = true


  def create? = user&.admin? || user&.user?
  def new?    = create?

  def update? = user&.admin? || user&.user?
  def edit?   = update?


  def destroy? = user&.admin? || user&.user?

 
  class Scope < Scope
    def resolve = scope.all
  end
end