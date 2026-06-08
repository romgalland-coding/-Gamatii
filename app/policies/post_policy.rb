class PostPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?    = true
  def create?  = user.present?
  def destroy? = record.user == user
end
