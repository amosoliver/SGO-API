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
end
