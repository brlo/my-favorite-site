module Admin
  # Подсказки для полей форм (см. combobox_controller.js): title и hint — для показа, остальное — подставляемые значения
  class AutocompleteController < BaseController
    def pages
      return deny_access unless can?('pages_read') || current_user.pages_owner.present?

      term = params[:term].to_s.strip
      return render(json: []) if term.length < 2

      scope = ::Page.where('title ILIKE :t OR path ILIKE :t', t: "%#{::Page.sanitize_sql_like(term)}%")
      scope = scope.or(::Page.where(id: term.to_i)) if term.match?(/\A\d+\z/)
      # для авторских страниц и разделов подсказываем только страницы-списки
      scope = scope.where(page_type: ::Page::PAGE_TYPES['список']) if params[:kind] == 'list'
      pages = scope.order(updated_at: :desc).limit(20).pluck(:id, :title, :path, :group_lang_id, :lang)

      render json: pages.map { |id, title, path, group_lang_id, lang|
        { id:, path:, group_lang_id:, title: "#{::FLAG_BY_LANG[lang]} #{title}", hint: "#{path} · ##{id}" }
      }
    end

    def dict_words
      return deny_access unless can?('dict_read')

      term = ::DictWord.word_clean_gr(params[:term])
      return render(json: []) if term.blank?

      words = ::DictWord.where('word_simple LIKE ?', "#{::DictWord.sanitize_sql_like(term)}%")
        .order(:word).limit(20).pluck(:word, :dict, :translation_short)

      render json: words.map { |word, dict, tr|
        { word:, title: word, hint: [::DictWord::DICTS.dig(dict, 'name'), tr].compact.join(' — ') }
      }
    end

    # подсказки тегов для поля тегов в форме статьи; правка тегов доступна редакторам статей
    def tags
      return deny_access unless can?('tags_manage') || can?('pages_update') || can?('pages_self_update') ||
                                can?('pages_editor_update') || current_user.pages_owner.present?

      term = params[:term].to_s.strip
      return render(json: []) if term.blank?

      tags = ::Tag.where('name ILIKE :t', t: "%#{::Tag.sanitize_sql_like(term)}%")
        .order(:name).limit(8).pluck(:name, :slug)

      render json: tags.map { |name, slug|
        { name:, title: name, hint: "/tags/#{slug}" }
      }
    end
  end
end
