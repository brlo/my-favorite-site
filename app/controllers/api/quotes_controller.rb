module Api
  class QuotesController < ApiApplicationController
    def list
      @quotes_pages = ::QuotesPage.only(:id, :title, :position, :lang).order(title: 1).all
    end

    def show
      set_quotes_page()
    end

    # POST /quotes_pages or /quotes_pages.json
    def create
      @quotes_page = ::QuotesPage.new(quotes_page_params)

      if @quotes_page.save
        render :show, status: :ok
      else
        render json: @quotes_page.errors, status: :unprocessable_entity
      end
    end

    def update
      set_quotes_page()
      if @quotes_page.update(quotes_page_params)
        render :show, status: :ok
      else
        render json: @quotes_page.errors, status: :unprocessable_entity
      end
    end

    def destroy
      set_quotes_page()

      begin
        @quotes_page.destroy!
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
    def set_quotes_page
      @quotes_page = ::QuotesPage.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def quotes_page_params
      params.require(:quotes_page).permit(:title, :meta_desc, :path, :lang, :body, :s_id, :position)
    end
  end
end
