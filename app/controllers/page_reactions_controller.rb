class PageReactionsController < ApplicationController
  skip_before_action :require_login_and_activation
  before_action :set_page

  # Положительная реакция без авторизации: одна на IP. Повторное нажатие на
  # выбранный вид снимает реакцию, нажатие на другой вид — меняет её.
  def toggle
    kind = params[:kind].to_s
    return head :unprocessable_entity unless ::PageReaction::KINDS.key?(kind)

    digest = ::PageReaction.digest_ip(request.ip)
    reaction = ::PageReaction.find_by(page_id: @page.id, ip_digest: digest)

    active =
      if reaction
        if reaction.kind == kind
          reaction.destroy!
          nil
        else
          reaction.update!(kind: kind)
          kind
        end
      else
        begin
          ::PageReaction.create!(page_id: @page.id, kind: kind, ip_digest: digest)
        rescue ActiveRecord::RecordNotUnique
          # параллельный запрос с того же IP уже поставил реакцию
          ::PageReaction.find_by(page_id: @page.id, ip_digest: digest)&.update!(kind: kind)
        end
        kind
      end

    counts = ::PageReaction.counts_by_kind(@page.id)

    respond_to do |format|
      format.json { render json: {counts: counts, active: active} }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@page, :reactions),
          partial: 'pages/reactions',
          locals: {page: @page, counts: counts, active: active}
        )
      end
      format.html do
        redirect_back fallback_location: ::Page.path_for(@page.lang, @page.path),
                     notice: active ? t('news.reaction_thanks') : t('news.reaction_removed')
      end
    end
  end

  private

  def set_page
    @page = ::Page.published.where(is_deleted: [nil, false], page_type: ::Page::PAGE_TYPES['статья'])
      .find(params[:page_id])
  end
end
