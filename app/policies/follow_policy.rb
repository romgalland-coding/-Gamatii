class FollowPolicy < ApplicationPolicy
  # `record` is the user being (un)followed; you can't follow yourself.
  def create?
    user.present? && user != record
  end

  def destroy?
    user.present? && user != record
  end
end
