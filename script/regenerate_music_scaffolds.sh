#!/usr/bin/env bash
set -euo pipefail

bin/rails g api_scaffold g_pais descricao:string sigla:string
bin/rails g api_scaffold g_estado g_pais:references descricao:string sigla:string
bin/rails g api_scaffold g_cidade g_estado:references descricao:string
bin/rails g api_scaffold g_igreja descricao:string endereco:string g_cidade:references ativo:boolean
bin/rails g api_scaffold c_coral descricao:string g_igreja:references ativo:boolean
bin/rails g api_scaffold o_orquestra descricao:string g_igreja:references ativo:boolean
bin/rails g api_scaffold g_tipo_pessoa descricao:string
bin/rails g api_scaffold g_pessoa descricao:string email:string g_tipo_pessoa:references g_igreja:references ativo:boolean
bin/rails g api_scaffold g_usuario g_pessoa:references email:string encrypted_password:string ativo:boolean
bin/rails g api_scaffold g_instrumento descricao:string ordem:integer
bin/rails g api_scaffold g_naipe g_instrumento:references descricao:string ordem:integer
bin/rails g api_scaffold g_pessoa_naipe g_pessoa:references g_instrumento:references g_naipe:references principal:boolean posicao:string
bin/rails g api_scaffold m_musica descricao:string tonalidade:string bpm:integer duracao:integer
bin/rails g api_scaffold m_material m_musica:references g_instrumento:references g_naipe:references tipo:string descricao:string arquivo_url:string
bin/rails g api_scaffold m_evento descricao:string data_evento:datetime g_igreja:references c_coral:references o_orquestra:references
bin/rails g api_scaffold m_evento_musica m_evento:references m_musica:references ordem:integer
