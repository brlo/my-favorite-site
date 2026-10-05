module Admin
  class DictWordsController < BaseController
    before_action -> { require_priv('dict_read') }
    before_action -> { require_priv('dict_create') }, only: %i[new create]
    before_action -> { require_priv('dict_update') }, only: %i[edit update]
    before_action -> { require_priv('dict_destroy') }, only: %i[destroy]
    before_action :set_dict_word, only: %i[edit update destroy]

    def index
      @term = params[:term].to_s.strip
      @dict = params[:dict].presence_in(::DictWord::DICTS.keys)

      @dict_words = ::DictWord.all
      @dict_words = @dict_words.where(dict: @dict) if @dict

      term = ::DictWord.word_clean_gr(@term.gsub(/[^[[:alnum:]]\s]/, ''))
      @dict_words =
        if term.present?
          # Ищем по началу слова в нескольких полях, сортируем по слову
          fields = %w[word_simple sinonim lexema tag transcription transcription_lat translation_short translation]
          pattern = "#{::DictWord.sanitize_sql_like(term)}%"
          @dict_words.where(fields.map { "LOWER(#{_1}) LIKE LOWER(:pattern)" }.join(' OR '), pattern:).order(:word)
        else
          # просто список — показываем недавно изменённые слова
          @dict_words.order(updated_at: :desc)
        end

      @dict_words = @dict_words.page(params[:page]).per(50)
    end

    def new
      @dict_word = ::DictWord.new(dict: params[:dict].presence || 'w', word: params[:word])
    end

    def create
      @dict_word = ::DictWord.new(dict_word_params)

      if @dict_word.save
        # остаёмся на форме создания, чтобы сразу добавлять следующее слово в тот же словарь
        redirect_to new_admin_dict_word_path(dict: @dict_word.dict), notice: "Слово «#{@dict_word.word}» создано"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @dict_word.update(dict_word_params)
        redirect_to admin_dict_words_path, notice: "Слово «#{@dict_word.word}» сохранено"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @dict_word.destroy!
      redirect_to admin_dict_words_path, notice: "Слово «#{@dict_word.word}» удалено", status: :see_other
    end

    # Самые частые слова и лексемы из текста Библии, которых ещё нет в словаре.
    # Тяжёлый запрос, поэтому грузится отдельно (lazy turbo-frame на форме создания слова).
    def waitings
      @dict = params[:dict].presence_in(::DictWord::DICTS.keys)
      words = []
      lexemas = []
      counts_by_word = {}
      counts_by_lexema = {}
      pack = 500

      10.times do |i|
        batch = ::Lexema.select(:word, :lexema_clean, :counts).order(counts: :desc).offset(i * pack).limit(pack).to_a
        break if batch.empty?

        batch.each do |l|
          counts_by_word[l.word] ||= l.counts
          counts_by_lexema[l.lexema_clean] ||= l.counts
        end
        words |= batch.map(&:word)
        lexemas |= batch.map(&:lexema_clean)

        # в словарь заглядываем только для того, чтобы убрать уже описанные слова
        described = ::DictWord.where(word_simple: (words + lexemas).uniq)
        described = described.where(dict: @dict) if @dict
        described = described.pluck(:word_simple)
        words -= described
        lexemas -= described

        break if words.size > 79 || lexemas.size > 79
      end

      @words = words.compact.first(80).map { { word: _1, counts: counts_by_word[_1] } }
      @lexemas = lexemas.compact.map { { word: _1, counts: counts_by_lexema[_1] } }
        .sort_by { -_1[:counts].to_i }.first(80)

      render layout: false
    end

    private

    def set_dict_word
      @dict_word = ::DictWord.find(params[:id])
    end

    def dict_word_params
      params.require(:dict_word).permit(
        :dict, :sinonim, :lexema, :word, :transcription, :transcription_lat,
        :translation_short, :translation, :tag, :desc
      )
    end
  end
end
