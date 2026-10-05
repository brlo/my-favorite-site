# API для оффлайн-приложения (Android). Только чтение, без авторизации.
module Api
  class OfflineController < ActionController::API
    before_action :validate_lang, only: %i[skeleton pages]

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

    private

    def validate_lang
      @lang = params[:lang].to_s
      head(:bad_request) unless @lang.match?(/\A[a-zA-Z\-]{2,10}\z/)
    end
  end
end
