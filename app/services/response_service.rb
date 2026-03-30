# frozen_string_literal: true

class ResponseService
  def self.pagy_index(query_result, params, controller, extra_meta = {})
    if query_result.empty?
      return { json: { message: "Nenhum registro encontrado", items: [] }.merge(extra_meta) }
    end

    if params[:page] || params[:per_page]
      pagy, paged = controller.send(:pagy, query_result, limit: params[:per_page] || 25)
      {
        json: {
          pagy: pagy_items(pagy.page, pagy.pages, pagy.count, pagy.limit),
          items: ActiveModelSerializers::SerializableResource.new(paged)
        }.merge(extra_meta)
      }
    else
      pagy, paged = controller.send(:pagy, query_result, limit: 25)
      {
        json: {
          pagy: pagy_items(pagy.page, pagy.pages, pagy.count, pagy.limit),
          items: ActiveModelSerializers::SerializableResource.new(paged)
        }.merge(extra_meta)
      }
    end
  rescue Pagy::OverflowError
    { json: { message: "Página fora do intervalo." }, status: :bad_request }
  end

  def self.pagy_items(current_page, total_pages, total_count, per_page)
    {
      current_page: current_page,
      total_pages: total_pages,
      total_count: total_count,
      per_page: per_page
    }
  end

  private_class_method :pagy_items
end
