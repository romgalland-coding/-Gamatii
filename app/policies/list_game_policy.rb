class ListGamePolicy < ApplicationPolicy
  def create?
    user.present? && record.list.user == user
  end

  def destroy?
    user.present? && record.list.user == user
  end
end
