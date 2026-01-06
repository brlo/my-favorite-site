module Api
  class SegmentsController < ApiApplicationController
    before_action :set_translation_project, only: [:index]
    before_action :set_segment, only: [:index, :destroy]
    before_action :reject_by_read_privs, only: [:index]
    before_action :reject_by_destroy_priv, only: [:destroy]

    # GET /api/translation_project/:translation_project_id/chapters/:chapter_number/segments
    def index
      chapter_number = params[:chapter_number].to_i

      if chapter_number < 1
        render json: { success: 'fail', message: "wrong chapter number: #{params[:chapter_number]}" }
      end

      # Загружаем сегменты для указанной главы
      segments = ::Segment.where(
        translation_project_id: @translation_project.id,
        chapter: chapter_number
      ).order(paragraph: :ASC, line: :ASC)

      # Предзагружаем переводы для каждого сегмента
      segments = segments.includes(translations: :user)

      # Форматируем данные для рендера
      formatted_segments = segments.map do |s|
        {
          id: s.id.to_s,
          chapter: s.chapter,
          paragraph: s.paragraph,
          line: s.line,
          text: s.text,
          lang: s.lang,
          is_original: s.is_original,
          open_tags: s.open_tags,
          close_tags: s.close_tags,
          translations: s.translations.map do |t|
            {
              id: t.id.to_s,
              text: t.text,
              lang: t.lang,
              source_lang: t.source_lang,
              user_name: t.user&.username || 'Аноним',
              created_at: t.created_at,
              vote_score: t.vote_score,
              votes: t.votes,
            }
          end
        }
      end

      render json: {
        success: 'ok',
        items: formatted_segments,
      }
    end

    # DELETE /api/translation_projects/:translation_project_id/segments
    def destroy
      @segment.destroy!
      render json: { success: 'ok' }
    end

    # разделить

    # обновить текст

    private

    def set_translation_project
      @translation_project = ::TranslationProject.find(params[:translation_project_id])
    end

    def set_segment
      @segment = ::Segment.find(params[:segment_id])
    end

    def reject_by_read_privs
      # TODO: проверять, что пользователь не заблокирован?
    end

    def reject_by_destroy_priv
      if ::Current.user.is_admin != true
        render json: {success: 'fail', errors: 'У вас нет доступа к этому действию.'}, status: 401
      end
    end
  end
end
