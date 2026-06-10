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

  def find_friends?
    user.present?
  end

  def search?
    user.present?
  end

  # Account management (the singular /profile) stays self-only.
  def edit?
    user == record
  end

  def update?
    user == record
  end
end
