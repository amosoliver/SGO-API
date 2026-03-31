# frozen_string_literal: true

# Associações:
# g_pessoa


# Atributos:
# string - email
# string - encrypted_password
# boolean - ativo

class GUsuario < ApplicationRecord
  attr_reader :password
  attr_accessor :password_confirmation

  belongs_to :g_pessoa
  has_many :g_usuario_perfis, foreign_key: :g_usuario_id, dependent: :destroy
  has_many :g_perfis, through: :g_usuario_perfis
  has_many :g_perfis_permissoes, through: :g_perfis
  has_many :g_permissoes, through: :g_perfis

  delegate :cpf, :descricao, to: :g_pessoa, allow_nil: true

  scope :active, -> { where(deleted_at: nil) }

  validates :g_pessoa, presence: true
  validates :email, presence: true
  validates :email, uniqueness: { scope: :deleted_at, conditions: -> { where(deleted_at: nil) } }
  validates :encrypted_password, presence: true
  validate :validate_password_confirmation

  before_validation :normalize_email

  def self.find_active_by_login(login)
    credential = login.to_s.strip
    return if credential.blank?

    relation = active.joins(:g_pessoa)
    if credential.include?("@")
      relation.find_by(email: credential.downcase)
    else
      normalized_cpf = GPessoa.normalize_cpf_value(credential)
      return if normalized_cpf.blank?

      relation.where("regexp_replace(coalesce(g_pessoas.cpf, ''), '[^0-9]', '', 'g') = ?", normalized_cpf).first
    end
  end

  def password=(raw_password)
    @password = raw_password
    self.encrypted_password = raw_password.present? ? BCrypt::Password.create(raw_password) : encrypted_password
  end

  def valid_password?(raw_password)
    return false if encrypted_password.blank? || raw_password.blank?

    BCrypt::Password.new(encrypted_password).is_password?(raw_password)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def nome
    descricao
  end

  def admin?
    adm? || maestro?
  end

  def g_perfil
    g_perfis.active.first
  end

  def g_perfil_id
    g_perfil&.id
  end

  def perfil_nome
    g_perfil&.descricao.to_s.upcase
  end

  def adm?
    perfil_nome == "ADM"
  end

  def maestro?
    perfil_nome == "MAESTRO"
  end

  def corista?
    perfil_nome == "CORISTA"
  end

  def associated_instrument_ids
    return GInstrumento.select(:id) unless corista?

    g_pessoa.g_pessoa_naipes.select(:g_instrumento_id).distinct
  end

  def associated_naipe_ids
    return GNaipe.select(:id) unless corista?

    g_pessoa.g_pessoa_naipes.select(:g_naipe_id).distinct
  end

  def associated_instrumento_naipe_ids
    return GInstrumentoNaipe.select(:id) unless corista?

    GInstrumentoNaipe.active
                     .joins("INNER JOIN g_pessoa_naipes ON g_pessoa_naipes.g_instrumento_id = g_instrumentos_naipes.g_instrumento_id AND g_pessoa_naipes.g_naipe_id = g_instrumentos_naipes.g_naipe_id")
                     .where(g_pessoa_naipes: { g_pessoa_id: g_pessoa_id })
                     .select(:id)
                     .distinct
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end

  def validate_password_confirmation
    return if password.blank?
    return if password_confirmation.nil? || password == password_confirmation

    errors.add(:password_confirmation, "não confere com a senha")
  end
end
