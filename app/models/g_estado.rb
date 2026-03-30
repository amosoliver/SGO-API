# frozen_string_literal: true

# Associações:
# g_pais


# Atributos:
# string - descricao
# string - sigla

class GEstado < ApplicationRecord
  belongs_to :g_pais
end
