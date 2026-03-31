# frozen_string_literal: true

# Associações:
# g_tipo_pessoa
# g_igreja


# Atributos:
# string - descricao
# string - email
# boolean - ativo

class GPessoa < ApplicationRecord
  has_one :g_usuario, dependent: :destroy
  has_many :g_pessoa_naipes, dependent: :destroy

  belongs_to :g_tipo_pessoa, optional: true
  belongs_to :g_igreja, optional: true

  before_validation :normalize_cpf

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      ativo
      cpf
      created_at
      created_by
      deleted_at
      descricao
      email
      g_igreja_id
      g_tipo_pessoa_id
      id
      updated_at
      updated_by
    ]
  end

  def self.normalize_cpf_value(value)
    value.to_s.gsub(/\D/, "")
  end

  private

  def normalize_cpf
    self.cpf = self.class.normalize_cpf_value(cpf) if respond_to?(:cpf) && cpf.present?
  end
end
