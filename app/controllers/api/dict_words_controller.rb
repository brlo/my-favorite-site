module Api
  class DictWordsController < ApiApplicationController
    before_action :reject_by_read_privs
    before_action :reject_by_create_privs, only: [:create]
    before_action :reject_by_update_privs, only: [:update]
    before_action :reject_by_destroy_privs, only: [:destroy]

    def list
      @dict_words = DictWord.limit(50)

      @dict_words = @dict_words.where(dict: params[:dict]) if params[:dict].present?
      @dict_words = @dict_words.limit([params[:limit].to_i, 100].min) if params[:limit].present?

      term = params[:term].to_s
      if term.present? && term.length > 0
        # слова показывает с сортировкой по слову
        term = term.gsub(/[^[[:alnum:]]\s]/, '')
        term = ::DictWord.word_clean_gr(term)
        q = [
          :word_simple, :sinonim, :lexema, :tag, :transcription, :transcription_lat,
          :translation_short, :translation,
        ].map do |n|
          { n => /#{term}.*/i }
        end
        @dict_words = @dict_words.any_of(q).order_by(w: 1)
      else
        # показываем недавно изменённые слова, если слово не ищут, а просто просят список
        @dict_words = @dict_words.order_by(updated_at: -1)
      end

      @dict_words.to_a

      render(json: {'success': 'ok', items: @dict_words.map(&:attrs_for_render)}, status: :ok)
    end

    def list_top_waitings
      lexemas = []
      ls = []
      ws = []
      skip = 0
      pack = 500

      10.times do
        # TODO: лексемы надо запросить отдельно
        lexemas += ::Lexema.only(:id, :word, :lexema_clean, :counts).skip(skip).order(counts: -1).first(pack)

        ws += lexemas.pluck(:word)
        ls += lexemas.pluck(:lexema_clean)
        ws = ws.uniq
        ls = ls.uniq

        # в словарь заглядываем только для того, чтобы убрать уже описаные слова
        dicts = DictWord
        dicts = dicts.where(dict: params[:dict]) if params[:dict].present?
        dicts = dicts.where(:word_simple.in => (ws+ls).uniq).pluck(:word_simple)

        dicts.each { |w| ws = (ws - [w]); ls = (ls - [w]) }

        if ls.count > 79 || ws.count > 79
          break
        else
          skip += pack
        end
      end

      # добавляем к словам количество повторений
      lexemas_l = lexemas.map { |l| [l.lexema_clean, l.counts] }.to_h
      lexemas_w = lexemas.map { |l| [l.word, l.counts] }.to_h
      # render
      ls = ls.map { |w| { word: w, counts: lexemas_l[w] } }
      ws = ws.map { |w| { word: w, counts: lexemas_w[w] } }

      # лексемы нуждаются в сортирокве по кол-ву повторений
      ls = ls.sort_by { _1[:counts] }.reverse

      render(json: {'success': 'ok', items: { words: ws, lexemas: ls} }, status: :ok)
    end

    def show
      set_dict_word()
      render(json: {'success': 'ok', item: @dict_word.attrs_for_render}, status: :ok)
    end

    # POST /menus
    def create
      @dict_word = DictWord.new(dict_word_params)

      # begin
        if @dict_word.save
          render(json: {'success': 'ok', item: @dict_word.attrs_for_render}, status: :ok)
        else
          # puts '=======ERRORS======='
          # puts @dict_word.errors.messages.inspect

          render json: @dict_word.errors, status: :unprocessable_entity
        end
      # rescue => e
      #   logger.error e.message
      #   logger.error e.backtrace.join("\n")
      #   raise(e)
      # end
    end

    def update
      set_dict_word()

      # begin
        if @dict_word.update(dict_word_params)
          render(json: {'success': 'ok', item: @dict_word.attrs_for_render}, status: :ok)
        else
          # puts '=======ERRORS======='
          # puts @dict_word.errors.messages.inspect
          render json: @dict_word.errors, status: :unprocessable_entity
        end
      # rescue => e
        # logger.error e.message
        # logger.error e.backtrace.join("\n")
      #   raise(e)
      # end
    end

    def destroy
      set_dict_word()

      begin
        @dict_word.destroy!
        render(json: {'success': 'ok', item: @dict_word.attrs_for_render}, status: :ok)
      rescue ActiveRecord::RecordNotDestroyed => error
        render json: {errors: error.record.errors}, status: 422
      end
    end

    private

    def success_response
      {'success': 'ok'}
    end

    def set_dict_word
      @dict_word = ::DictWord.find(params[:id]) || not_found!()
    end

    def dict_word_params
      params.require(
        :dict_word
      ).except(
        :id, :created_at, :updated_at, :src_lang, :dst_lang
      ).permit(
        :dict, :sinonim, :lexema, :word, :transcription, :transcription_lat,
        :translation_short, :translation, :tag, :desc
      )
    end

    def reject_by_read_privs;    ability?('dict_read'); end
    def reject_by_create_privs;  ability?('dict_create'); end
    def reject_by_update_privs;  ability?('dict_update'); end
    def reject_by_destroy_privs; ability?('dict_destroy'); end
  end
end
