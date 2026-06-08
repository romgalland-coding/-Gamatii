class UserPolicy < ApplicationPolicy
  # Public profile pages and their follower/following lists are viewable by anyone.
  def show?
    true
  end

  def followers?
    true
  end

  def following?
    true
  end

  # Account management (the singular /profile) stays self-only.
  def edit?
    user == record
  end

  def update?
    user == record
  end
end
