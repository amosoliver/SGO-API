class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  RANSACK_EXCLUDED_ATTRIBUTES = %w[
    encrypted_password
    password
    password_confirmation
    reset_password_token
    unlock_token
    confirmation_token
    token_primeiro_acesso
    refresh_token
  ].freeze

  def self.ransackable_attributes(_auth_object = nil)
    column_names - RANSACK_EXCLUDED_ATTRIBUTES
  end

  def self.ransackable_associations(_auth_object = nil)
    reflect_on_all_associations.map { |association| association.name.to_s }
  end
end
