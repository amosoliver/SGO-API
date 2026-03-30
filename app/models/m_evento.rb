# frozen_string_literal: true

# Associações:
# g_igreja
# c_coral
# o_orquestra


# Atributos:
# string - descricao
# datetime - data_evento

class MEvento < ApplicationRecord
  belongs_to :g_igreja
  belongs_to :c_coral
  belongs_to :o_orquestra
end
