class LikePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def create?  = user.present? && record.user == user
  def destroy? = record.user == user
end
