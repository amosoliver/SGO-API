# frozen_string_literal: true

class MateriaisLoteUploadService
  def initialize(m_musica:, materiais:, url_options:)
    @m_musica = m_musica
    @materiais = Array(materiais)
    @url_options = url_options
  end

  def call
    return Result.failure(["Nenhum material foi informado para upload."], 422, "Não foi possível enviar os materiais.") if @materiais.blank?

    created_items = []

    MMaterial.transaction do
      @materiais.each_with_index do |material_params, index|
        created_items << create_material!(material_params, index)
      end
    end

    Result.success(created_items, 201, "Materiais enviados com sucesso.")
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(e.record.errors.full_messages, 422, "Não foi possível enviar os materiais.")
  end

  private

  def create_material!(material_params, index)
    arquivo = material_params[:arquivo]
    raise_record_invalid!("Arquivo não informado para o item #{index + 1}.") if arquivo.blank?

    material = MMaterial.new(
      descricao: material_params[:descricao].presence || default_description(arquivo),
      tipo: material_params[:tipo],
      g_instrumento_naipe_id: material_params[:g_instrumento_naipe_id],
      m_musica: @m_musica
    )

    material.save!
    material.arquivo.attach(arquivo)
    material.sync_arquivo_url!(@url_options)
    material
  end

  def default_description(arquivo)
    File.basename(arquivo.original_filename.to_s, File.extname(arquivo.original_filename.to_s))
  end

  def raise_record_invalid!(message)
    material = MMaterial.new
    material.errors.add(:arquivo, message)
    raise ActiveRecord::RecordInvalid.new(material)
  end
end
