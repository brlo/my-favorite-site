module Admin
  # Управление тегами статей: переименование, адрес, переводы имени, удаление.
  # Назначение тегов статьям — в форме статьи (Admin::PagesController).
  class TagsController < BaseController
    before_action :require_tags_priv
    before_action :set_tag, only: %i[edit update destroy]

    def index
      @term = params[:term].to_s.strip

      scope = ::Tag.left_joins(:taggings)
        .select('tags.*, COUNT(taggings.id) AS pages_count')
        .group('tags.id')
        .order(::Arel.sql('COUNT(taggings.id) DESC, tags.name'))
      scope = scope.where('tags.name ILIKE :t', t: "%#{::Tag.sanitize_sql_like(@term)}%") if @term.length > 1

      @tags = scope.page(params[:page]).per(50)
    end

    def edit
    end

    def update
      if @tag.update(tag_params)
        redirect_to admin_tags_path, notice: 'Тег сохранён'
      else
        flash.now[:alert] = 'Не удалось сохранить тег'
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tag.destroy!
      redirect_to admin_tags_path, notice: "Тег «#{@tag.name}» удалён", status: :see_other
    end

    private

    def require_tags_priv
      require_priv('tags_manage')
    end

    def set_tag
      @tag = ::Tag.find(params[:id])
    end

    def tag_params
      permitted = params.require(:tag).permit(:name, :slug, names: ::I18n.available_locales.map(&:to_s))
      # пустой адрес = сгенерировать заново из имени
      permitted[:slug] = permitted[:slug].to_s.strip.presence
      # пустые переводы имени убираем: будет показываться каноническое имя
      permitted[:names] = permitted[:names].to_h.transform_values { |value| value.to_s.strip }.compact_blank
      permitted
    end
  end
end
