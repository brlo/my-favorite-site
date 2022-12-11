module Admin
  class QuotesPagesController < BaseController
    before_action :set_quotes_page, only: %i[ show edit update destroy ]

    # GET /quotes_pages or /quotes_pages.json
    def index
      @quotes_pages = QuotesPage.order(position: :asc).all
    end

    # GET /quotes_pages/1 or /quotes_pages/1.json
    def show
    end

    # GET /quotes_pages/new
    def new
      @quotes_page = QuotesPage.new
    end

    # GET /quotes_pages/1/edit
    def edit
    end

    # POST /quotes_pages or /quotes_pages.json
    def create
      @quotes_page = QuotesPage.new(quotes_page_params)

      respond_to do |format|
        if @quotes_page.save
          format.html { redirect_to admin_quotes_page_url(@quotes_page), notice: "Страница создана." }
          format.json { render :show, status: :created, location: @quotes_page }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @quotes_page.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /quotes_pages/1 or /quotes_pages/1.json
    def update
      respond_to do |format|
        if @quotes_page.update(quotes_page_params)
          format.html { redirect_to admin_quotes_page_url(@quotes_page), notice: "Обновление страницы прошло успешно." }
          format.json { render :show, status: :ok, location: @quotes_page }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @quotes_page.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /quotes_pages/1 or /quotes_pages/1.json
    def destroy
      @quotes_page.destroy

      respond_to do |format|
        format.html { redirect_to admin_quotes_pages_url, notice: "Страница успешно удалена." }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_quotes_page
      @quotes_page = QuotesPage.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def quotes_page_params
      params.require(:quotes_page).permit(:title, :path, :lang, :body, :s_id, :position)
    end
  end
end
