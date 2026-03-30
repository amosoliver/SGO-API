# frozen_string_literal: true

# Associações:
# g_estado


# Atributos:
# string - descricao

class GCidade < ApplicationRecord
  belongs_to :g_estado
end
