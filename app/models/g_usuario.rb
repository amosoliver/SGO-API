# frozen_string_literal: true

# Associações:
# g_pessoa


# Atributos:
# string - email
# string - encrypted_password
# boolean - ativo

class GUsuario < ApplicationRecord
  belongs_to :g_pessoa
end
