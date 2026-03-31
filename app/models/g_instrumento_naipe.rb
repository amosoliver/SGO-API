# frozen_string_literal: true

class GInstrumentoNaipe < ApplicationRecord
  self.table_name = "g_instrumentos_naipes"

  belongs_to :g_instrumento
  belongs_to :g_naipe

  scope :active, -> { where(deleted_at: nil) }

  validates :g_naipe_id, uniqueness: { scope: %i[g_instrumento_id deleted_at], conditions: -> { where(deleted_at: nil) } }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at created_by deleted_at g_instrumento_id g_naipe_id id ordem updated_at updated_by]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[g_instrumento g_naipe]
  end
end
