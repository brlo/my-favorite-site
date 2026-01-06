module Api
  class TranslationsController < ApiApplicationController
    before_action :set_translation, only: [:destroy, :vote]
    before_action :reject_by_create_privs, only: [:create]
    before_action :reject_by_destroy_priv, only: [:destroy]

    # POST /api/translations
    def create
      translation = ::Translation.new(translation_params)
      translation.user_id = ::Current.user.id

      if translation.save
        render json: { success: 'ok', translation: translation_data(translation) }
      else
        render json: { success: 'fail', errors: translation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/translations
    def destroy
      if ::Current.user.id == @translation.u_id
        @translation.destroy!
        render json: { success: 'ok' }
      else
        render json: { success: 'fail' }
      end
    end

    # POST /api/translations/:id/vote
    def vote
      is_up_vote = params[:vote].to_i > 0
      is_saved = is_up_vote ? @translation.up_vote() : @translation.down_vote()

      if is_saved
        render json: { success: 'ok', vote_score: translation.vote_score }
      else
        render json: { success: 'fail', errors: translation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_translation_project
      @translation_project = ::TranslationProject.find(params[:translation_project_id])
    end

    def set_segment
      @segment = ::Segment.find(params[:segment_id])
    end

    def set_translation
      @translation = ::Translation.find(params[:translation_id])
    end

    # Only allow a list of trusted parameters through.
    def translation_params
      params.require(:translation).except(
        :id, :created_at, :updated_at
      ).permit(
        :text, :lang, :source_lang, :segment_id
      )
    end

    def reject_by_create_priv
      if ::Current.user.is_admin != true
        render json: {success: 'fail', errors: 'У вас нет доступа к этому действию.'}, status: 401
      end
    end

    def reject_by_destroy_priv
      if ::Current.user.is_admin != true
        render json: {success: 'fail', errors: 'У вас нет доступа к этому действию.'}, status: 401
      end
    end

    def translation_data(translation)
      {
        id: translation.id.to_s,
        text: translation.text,
        lang: translation.lang,
        source_lang: translation.source_lang,
        created_at: translation.created_at,
        vote_score: translation.vote_score
      }
    end
  end
end
