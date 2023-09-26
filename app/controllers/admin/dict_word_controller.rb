module Admin
  class DictWordController < BaseController
    # before_action :set_quotes_page, only: %i[ show edit update destroy ]

    # GET /dict_words or /dict_words.json
    def index
      # надо тут ещё фильтры по словарям добавить, а на странице выпадающий список сделать
      @dict_words = DictWord.order(w: 1).limit(500).to_a
    end

    # GET /dict_words/1 or /dict_words/1.json
    def show
    end

    # GET /dict_words/new
    def new
      @quotes_page = DictWord.new
    end

    # GET /dict_words/1/edit
    def edit
    end

    # POST /dict_words or /dict_words.json
    def create
      @quotes_page = DictWord.new(dict_word_params)

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

    # PATCH/PUT /dict_words/1 or /dict_words/1.json
    def update
      respond_to do |format|
        if @dict_word.update(dict_word_params)
          format.html { redirect_to admin_dict_word_url(@dict_word), notice: "Обновление страницы прошло успешно." }
          format.json { render :show, status: :ok, location: @dict_word }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @dict_word.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /dict_words/1 or /dict_words/1.json
    def destroy
      @dict_word.destroy

      respond_to do |format|
        format.html { redirect_to admin_dict_words_url, notice: "Страница успешно удалена." }
        format.json { head :no_content }
      end
    end

    def dump
      data = ''

      ::QuotesPage.order(title: 1).each do |qp|
        data += "<START>\n"
        data += "title\n"
        data += qp.title.to_s + "\n"
        data += "meta_desc\n"
        data += qp.meta_desc.to_s + "\n"
        data += "lang\n"
        data += qp.lang.to_s + "\n"
        data += "path\n"
        data += qp.path.to_s + "\n"
        data += "s_id\n"
        data += qp.s_id.to_s + "\n"
        data += "position\n"
        data += qp.position.to_s + "\n"
        data += "body\n"
        data += qp.body.to_s + "\n"
        data += "<END>\n"
      end

      send_data(
        data,
        :filename => "bibleox-quotes-#{Date.today}.txt",
        :type => "text/plain"
      )
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_dict_word
      @dict_word = DictWord.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dict_word_params
      params.require(:dict_word).permit(:title, :meta_desc, :path, :lang, :body, :s_id, :position)
    end
  end
end
