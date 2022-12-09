module Admin
  class QuotesSubjectsController < BaseController
    before_action :set_quotes_subject, only: %i[ show edit update destroy ]

    # GET /quotes_subjects or /quotes_subjects.json
    def index
      @quotes_subjects = QuotesSubject.all
    end

    # GET /quotes_subjects/1 or /quotes_subjects/1.json
    def show
    end

    # GET /quotes_subjects/new
    def new
      @quotes_subject = QuotesSubject.new
    end

    # GET /quotes_subjects/1/edit
    def edit
    end

    # POST /quotes_subjects or /quotes_subjects.json
    def create
      @quotes_subject = QuotesSubject.new(quotes_subject_params)

      respond_to do |format|
        if @quotes_subject.save
          format.html { redirect_to admin_quotes_subject_url(@quotes_subject), notice: "Создание темы успешно." }
          format.json { render :show, status: :created, location: @quotes_subject }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @quotes_subject.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /quotes_subjects/1 or /quotes_subjects/1.json
    def update
      respond_to do |format|
        if @quotes_subject.update(quotes_subject_params)
          format.html { redirect_to admin_quotes_subject_url(@quotes_subject), notice: "Обновление темы успешно." }
          format.json { render :show, status: :ok, location: @quotes_subject }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @quotes_subject.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /quotes_subjects/1 or /quotes_subjects/1.json
    def destroy
      @quotes_subject.destroy

      respond_to do |format|
        format.html { redirect_to admin_quotes_subjects_url, notice: "Удаление темы успешно." }
        format.json { head :no_content }
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_quotes_subject
        @quotes_subject = QuotesSubject.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def quotes_subject_params
        params.require(:quotes_subject).permit(:title_ru, :title_en, :title_gr, :title_jp, :desc, :p_id)
      end
  end
end
