require "basic_auth_constraint"
require "swagger_openapi_json"
require "swagger_ui_html"

Rails.application.routes.draw do
  devise_for :users, skip: :all

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :m_evento_musicas
      resources :m_eventos
      resources :m_materiais
      resources :m_musicas
      resources :g_pessoa_naipes
      resources :g_naipes
      resources :g_instrumentos
      resources :g_usuarios
      resources :g_pessoas
      resources :g_tipos_pessoa
      resources :o_orquestras
      resources :c_corais
      resources :g_igrejas
      resources :g_cidades
      resources :g_estados
      resources :g_paises
      post "auth/login", to: "auth#login"
      post "auth/refresh_token", to: "auth#refresh_token"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"
      patch "auth/update_password", to: "auth#update_password"
      post "auth/primeiro_acesso", to: "auth#primeiro_acesso"
      get "auth/permissions/:jti", to: "auth#get_permissions"
      post "auth/sincronizar_permissoes", to: "auth#sincronizar_permissoes"

      resources :users
      resources :g_perfis
      resources :g_permissoes, only: %i[index show create update destroy]
      resources :g_perfis_permissoes, only: %i[show create update destroy]
    end
  end

  swagger_enabled = ENV.fetch("ENABLE_SWAGGER", Rails.env.development? ? "true" : "false") == "true"

  if swagger_enabled
    get "/swagger/openapi.json", to: SwaggerOpenapiJson
    get "/swagger", to: SwaggerUiHtml
  end
end
