# frozen_string_literal: true

# Associações:
# g_pessoa
# g_instrumento
# g_naipe


# Atributos:
# boolean - principal
# string - posicao

class GPessoaNaipe < ApplicationRecord
  belongs_to :g_pessoa
  belongs_to :g_instrumento
  belongs_to :g_naipe

  validate :instrumento_compativel_com_naipe

  private

  def instrumento_compativel_com_naipe
    return if g_instrumento_id.blank? || g_naipe_id.blank?
    return if GInstrumentoNaipe.active.exists?(g_instrumento_id: g_instrumento_id, g_naipe_id: g_naipe_id)

    errors.add(:g_naipe_id, "não está vinculado ao instrumento informado")
  end
end
