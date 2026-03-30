# frozen_string_literal: true

# Associações:
# g_cidade


# Atributos:
# string - descricao
# string - endereco
# boolean - ativo

class GIgreja < ApplicationRecord
  belongs_to :g_cidade
end
