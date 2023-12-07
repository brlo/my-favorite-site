module Api
  class QuotesSubjectsController < ApiApplicationController
    def list
      # @quotes_subjects = ::QuotesSubject.only(:id, :title, :position, :lang).order(title: 1).all
      @quotes_subjects = ::QuotesSubject.order(position: 1).all
    end

    def show
      set_quotes_subject()
    end

    # POST /quotes_subjects or /quotes_subjects.json
    def create
      @quotes_subject = QuotesSubject.new(quotes_subject_params)

      if @quotes_subject.save
        render :show, status: :ok
      else
        render json: @quotes_subject.errors, status: :unprocessable_entity
      end
    end

    def update
      set_quotes_subject()
      if @quotes_subject.update(quotes_subject_params)
        render :show, status: :ok
      else
        render json: @quotes_subject.errors, status: :unprocessable_entity
      end
    end

    def destroy
      set_quotes_subject()

      begin
        @quotes_subject.destroy!
        render json: success_response
      rescue ActiveRecord::RecordNotDestroyed => error
        render json: {errors: error.record.errors}, status: 422
      end
    end

    private

    def success_response
      {'success': 'ok'}
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_quotes_subject
      @quotes_subject = ::QuotesSubject.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def quotes_subject_params
      params.require(:quotes_subject).permit(
        :title_ru, :title_en, :title_gr, :title_jp,
        :desc_ru, :desc_en, :desc_gr, :desc_jp,
        :p_id, :position
      )
    end
  end
end
