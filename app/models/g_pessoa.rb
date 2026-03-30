# frozen_string_literal: true

# Associações:
# g_tipo_pessoa
# g_igreja


# Atributos:
# string - descricao
# string - email
# boolean - ativo

class GPessoa < ApplicationRecord
  belongs_to :g_tipo_pessoa
  belongs_to :g_igreja
end
