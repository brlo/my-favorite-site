# API для оффлайн-приложения (Android). Чтение без авторизации.
module Api
  class OfflineController < ActionController::API
    before_action :validate_lang, only: %i[skeleton pages feed reading_now]

    # GET /api/offline/manifest?locale=ru
    def manifest
      locale = params[:locale].to_s.presence_in(::I18n.available_locales.map(&:to_s)) || 'ru'
      render json: ::Offline::Export.manifest(locale: locale)
    end

    # GET /api/offline/bible/:tr_code
    def bible
      tr_code = params[:tr_code].to_s
      return head(:not_found) unless ::Offline::Export.tr_codes.include?(tr_code)

      path = ::Offline::Export.bible_pack_path(tr_code)
      return head(:not_found) unless path

      send_file path, type: 'application/gzip', disposition: 'attachment'
    end

    # GET /api/offline/skeleton?lang=ru&since=1700000000
    def skeleton
      render json: ::Offline::Export.skeleton(lang: @lang, since: params[:since].to_i)
    end

    # GET /api/offline/pages?lang=ru&ids=1,2,3
    def pages
      ids = params[:ids].to_s.split(',').select { _1.match?(/\A\d+\z/) }
      return render(json: { pages: [] }) if ids.empty?

      render json: { pages: ::Offline::Export.pages(lang: @lang, ids: ids) }
    end

    # GET /api/offline/tokens?ids=1,2,3
    # Токены маячка для уже скачанных страниц (в тексте они приходят вместе с body).
    def tokens
      ids = params[:ids].to_s.split(',').select { _1.match?(/\A\d+\z/) }
      render json: { tokens: ::Offline::Export.visit_tokens(ids) }
    end

    # GET /api/offline/feed?lang=ru&page=1
    def feed
      response.headers['Cache-Control'] = 'no-store'
      render json: ::Offline::Export.feed(lang: @lang, page: params[:page], ip: request.ip)
    end

    # GET /api/offline/reading_now?lang=ru
    def reading_now
      response.headers['Cache-Control'] = 'no-store'
      render json: ::Offline::Export.reading_now(lang: @lang)
    end

    private

    def validate_lang
      @lang = params[:lang].to_s
      head(:bad_request) unless @lang.match?(/\A[a-zA-Z\-]{2,10}\z/)
    end
  end
end
