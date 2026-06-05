class ChatPolicy < ApplicationPolicy
  def show?
    user.present? && record.user == user
  end

  def create?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
