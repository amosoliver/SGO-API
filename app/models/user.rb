# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  belongs_to :g_perfil, optional: true
  has_many :g_usuario_perfis, dependent: :destroy
  has_many :g_perfis_permissoes, through: :g_perfil
  has_many :g_permissoes, through: :g_perfis_permissoes

  scope :active, -> { where(deleted_at: nil) }

  validates :email, presence: true, uniqueness: { scope: :deleted_at, conditions: -> { where(deleted_at: nil) } }
  validates :cpf, uniqueness: { scope: :deleted_at, conditions: -> { where(deleted_at: nil) } }, allow_blank: true
  validate :check_cpf

  before_validation :normalize_email
  before_validation :ensure_first_access_token

  def mascarar_email
    return "" unless email.to_s.include?("@")

    local, domain = email.split("@", 2)
    return email if local.blank? || domain.blank?

    "#{local.first(2)}***@#{domain}"
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end

  def ensure_first_access_token
    return unless primeiro_acesso?
    return if token_primeiro_acesso.present?

    self.token_primeiro_acesso = SecureRandom.hex(16)
  end

  def check_cpf
    return if cpf.blank? || CPF.valid?(cpf)

    errors.add(:cpf, "CPF não é válido.")
  end
end
