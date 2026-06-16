class TranslationsController < ApplicationController
  before_action :set_segment
  before_action :set_translation, except: %w[new create]

  skip_before_action :require_login, only: %w[show voters]
  before_action :require_admin, only: %w[approve]

  # голосование
  rate_limit to: 2, within: 10.seconds, by: -> { request.ip }, only: %w[upvote downvote], if: -> { logged_in? && !current_user.is_admin? }
  rate_limit to: 1, within: 10.seconds, by: -> { current_user.id }, only: %w[upvote downvote], if: -> { logged_in? && !current_user.is_admin? }

  # работа с переводами
  rate_limit to: 1, within: 10.seconds, by: -> { request.ip }, only: %w[create update destroy], if: -> { logged_in? && !current_user.is_admin? }
  rate_limit to: 1, within: 10.seconds, by: -> { current_user.id }, only: %w[create update destroy], if: -> { logged_in? && !current_user.is_admin? }

  def new
    @translation = Translation.new(
      translation_project_id: params[:translation_project_id],
      segment_id: params[:segment_id]
    )

    render partial: "translations/new_translation_form",
           locals: { translation: @translation },
           layout: false
  end

  def show
    render partial: 'translations/translation_card',
      locals: { translation: @translation, target_lang: @translation.lang }
  end

  def create
    @translation = @segment.translations.new(
      translation_params.merge(
        user: current_user,
        translation_project_id: params[:translation_project_id]
      )
    )

    if @translation.save
      render turbo_stream: [
        # Перерисовать весь сегмент:
        turbo_stream.update(
          "segment-with-translations-#{@translation.segment_id}",
          partial: "translations/segment_with_translations",
          locals: { segment: @translation.segment.reload }
        ),

        # Обновить только этот один перевод:
        # turbo_stream.append(
        #   "translations_list_#{@segment.id}",
        #   partial: 'translations/translation_card',
        #   locals: { translation: @translation }
        # ),

        # Очищаем форму после успешной отправки
        turbo_stream.update(
          "new_translation_form_#{@translation.segment_id}",
          ""
        )
      ]
    else
      render turbo_stream: turbo_stream.update(
        "new_translation_form_#{params[:segment_id]}",
        partial: "translations/new_translation_form",
        locals: { segment: @translation.segment, translation: @translation },
        layout: false
      )
    end
  end

  def edit
    if @translation.editable_by?(current_user)
      render partial: "translations/edit_form",
            locals: { translation: @translation },
            layout: false
    else
      head :unprocessable_entity
    end
  end

  def update
    if @translation.editable_by?(current_user) && @translation.update(translation_params)
      render partial: 'translations/translation_card',
        locals: { translation: @translation, target_lang: @translation.lang }
    else
      render partial: "translations/edit_form",
            locals: { translation: @translation },
            layout: false
    end
  end

  def destroy
    if @translation.editable_by?(current_user) && @translation.destroy
      # Удалить только этот перевод:
      # render turbo_stream: turbo_stream.remove(
      #   "translation-#{ @translation.id }"
      # )

      # Перерисовать весь сегмент:
      render turbo_stream: [
        turbo_stream.update(
          "segment-with-translations-#{@translation.segment_id}",
          partial: "translations/segment_with_translations",
          locals: { segment: @translation.segment }
        )
      ]
    else
      head :unprocessable_entity
    end
  end

  def upvote
    if @translation.upvote(current_user)
      render partial: 'translations/translation_card',
        locals: { translation: @translation, target_lang: @translation.lang }
    else
      head :unprocessable_entity
    end
  end

  def downvote
    is_user_already_make_translation = @translation.segment.is_user_already_make_translation(user: current_user, lang: @translation.lang)

    if is_user_already_make_translation && @translation.downvote(current_user)
      render partial: 'translations/translation_card',
        locals: { translation: @translation, target_lang: @translation.lang }
    else
      head :unprocessable_entity
    end
  end

  def approve
    if @translation.update!(is_approved: !@translation.is_approved)
      render turbo_stream: [
        turbo_stream.update(
          "segment-with-translations-#{@translation.segment_id}",
          partial: "translations/segment_with_translations",
          locals: { segment: @translation.segment }
        )
      ]
    else
      head :unprocessable_entity
    end
  end

  def voters
    user_ids = @translation.votes.to_h.keys
    users_by_id = ::User.where(id: user_ids).to_a.index_by(&:id) if user_ids.any?

    if users_by_id
      @upvoters = @translation.votes.map { |k,v| v['v'] == 1 ? [users_by_id[k.to_i], v['t']] : nil }.compact
      @downvoters = @translation.votes.map { |k,v| v['v'] == -1 ? [users_by_id[k.to_i], v['t']] : nil }.compact

      render partial: "translations/voters_list",
            locals: { upvoters: @upvoters, downvoters: @downvoters, translation: @translation },
            layout: false
    else
      head :unprocessable_entity
    end
  end

  private

  def set_segment
    @segment = Segment.find(params[:segment_id])
  end

  def set_translation
    @translation = Translation.find(params[:id])
  end

  def translation_params
    params.require(:translation).permit(:text, :sub_text, :lang, :source_lang)
  end
end
