# frozen_string_literal: true

# Associações:
# g_instrumento


# Atributos:
# string - descricao
# integer - ordem

class GNaipe < ApplicationRecord
  belongs_to :g_instrumento
end
