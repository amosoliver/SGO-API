# frozen_string_literal: true

# Associações:
# g_igreja


# Atributos:
# string - descricao
# boolean - ativo

class CCoral < ApplicationRecord
  belongs_to :g_igreja
end
