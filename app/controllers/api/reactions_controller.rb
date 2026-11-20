# Реакции на статьи для мобильного приложения: JSON вместо HTML-формы.
# Как и на сайте, авторизация не нужна, одна реакция на IP.
module Api
  class ReactionsController < ActionController::API
    before_action :set_page

    # GET /api/offline/reactions?page_id=1
    def show
      render json: {
        counts: ::PageReaction.counts_by_kind(@page.id),
        active: ::PageReaction.kind_for(@page.id, request.ip),
      }
    end

    # POST /api/offline/reactions {page_id, kind}
    def toggle
      kind = params[:kind].to_s
      return head :unprocessable_entity unless ::PageReaction::KINDS.key?(kind)

      render json: ::PageReaction.toggle!(page: @page, kind: kind, ip: request.ip)
    end

    private

    def set_page
      @page = ::Page.published
        .where(is_deleted: [nil, false], page_type: ::Page::PAGE_TYPES['статья'])
        .find_by(id: params[:page_id])
      head :not_found unless @page
    end
  end
end
