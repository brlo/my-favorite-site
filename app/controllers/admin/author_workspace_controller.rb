# Кабинет автора: управление меню и статьями с публичной страницы автора.
# Все ответы — turbo_stream, поэтому панель обновляется без перезагрузки страницы.
module Admin
  class AuthorWorkspaceController < BaseController
    before_action :set_author_page
    before_action :require_author_page_access
    before_action :set_item, only: %i[update move destroy create_page_for_item destroy_page]

    # Содержимое рамки кабинета. Открывается только внутри страницы автора:
    # прямой заход в /admin/author/:id возвращает читателя на его публичную страницу.
    def show
      unless request.headers['Turbo-Frame'].present?
        return redirect_to ::Page.path_for(@author_page.lang, @author_page.path)
      end

      render partial: 'admin/author_workspace/workspace', locals: workspace_locals
    end

    # Новая статья (сразу создаётся страница) или новый раздел (только пункт меню)
    def create
      title = params[:title].to_s.squish
      return render_workspace(alert: 'Введите название', status: :unprocessable_entity) if title.blank?

      parent_id = params[:parent_id].presence&.to_i
      if parent_id && !author_menu_ids.include?(parent_id)
        return render_workspace(alert: 'Раздел не найден. Обновите страницу и попробуйте снова.', status: :unprocessable_entity)
      end

      if params[:kind] == 'section'
        create_section(title, parent_id)
      else
        create_article(title, parent_id)
      end
    end

    # Переименование и перенос в другой раздел
    def update
      title = params[:title].to_s.squish
      return render_workspace(alert: 'Название не может быть пустым', status: :unprocessable_entity) if title.blank?

      page = page_for_item(@item)
      if page && !can_manage_page?(page)
        return render_workspace(alert: 'Нет прав менять эту статью', status: :forbidden)
      end

      parent_specified = params.key?(:parent_id)
      new_parent_id = parent_specified ? params[:parent_id].presence&.to_i : @item.parent_id
      if new_parent_id && !author_menu_ids.include?(new_parent_id)
        return render_workspace(alert: 'Раздел не найден. Обновите страницу и попробуйте снова.', status: :unprocessable_entity)
      end
      if new_parent_id && (new_parent_id == @item.id || descendant_ids(@item).include?(new_parent_id))
        return render_workspace(alert: 'Нельзя переместить пункт внутрь самого себя', status: :unprocessable_entity)
      end

      parent_changed = parent_specified && new_parent_id != @item.parent_id
      ::ActiveRecord::Base.transaction do
        if parent_changed
          position = ::Menu.next_position(@author_page.id, new_parent_id)
          @item.update!(title:, parent_id: new_parent_id, priority: position, position:)
        else
          @item.update!(title:)
        end
        page.update!(title:) if page
      end
      renumber!(siblings_of(new_parent_id)) if parent_changed
      expire_page_cache(page.path, page.lang) if page

      notice = parent_changed ? "«#{title}» перенесено" : "Название изменено на «#{title}»"
      render_workspace(notice:)
    rescue ::ActiveRecord::RecordInvalid => e
      render_workspace(alert: "Не удалось сохранить: #{e.record.errors.full_messages.to_sentence}", status: :unprocessable_entity)
    end

    # Перемещение: кнопками (up/down/in/out) или мышью (target_id + position)
    def move
      if params[:target_id].present?
        move_relative_to(params[:target_id].to_i, params[:position].to_s)
      else
        case params[:direction].to_s
        when 'up'    then move_by_offset(-1)
        when 'down'  then move_by_offset(1)
        when 'in'    then indent_item
        when 'out'   then outdent_item
        else
          render_workspace(alert: 'Неизвестное перемещение', status: :unprocessable_entity)
        end
      end
    end

    # Убрать пункт из меню. Сама статья (если она есть) остаётся на сайте.
    def destroy
      if @item.childs.exists?
        return render_workspace(alert: 'Сначала уберите из меню вложенные пункты этого раздела.', status: :unprocessable_entity)
      end

      title = @item.title
      page = page_for_item(@item)
      @item.destroy!
      notice = page ? "Пункт «#{title}» убран из меню. Статья осталась на сайте." : "Раздел «#{title}» убран из меню."
      render_workspace(notice:)
    end

    # Удалить саму статью — необратимо. Вызывается отдельным действием
    # из блока «Удалить статью навсегда» в редакторе пункта.
    def destroy_page
      page = page_for_item(@item)
      return render_workspace(alert: 'У этого пункта меню нет статьи', status: :unprocessable_entity) if page.nil?
      return render_workspace(alert: 'Нет прав удалить эту статью', status: :forbidden) unless can_manage_page?(page)
      return render_workspace(alert: 'Сначала уберите из меню вложенные пункты этого раздела.', status: :unprocessable_entity) if @item.childs.exists?
      return render_workspace(alert: 'У статьи есть вложенные страницы — сначала удалите их.', status: :unprocessable_entity) if page.children.exists?

      title = page.title
      expire_page_cache(page.path, page.lang)
      ::ActiveRecord::Base.transaction do
        # ссылки на удалённую статью в чужих меню превращаем в заголовки разделов
        ::Menu.where(path: page.path).where.not(id: @item.id).update_all(path: nil, updated_at: ::Time.current) # rubocop:disable Rails/SkipsModelValidations
        page.destroy!
        @item.destroy!
      end

      render_workspace(notice: "Статья «#{title}» удалена без возможности восстановления")
    end

    # Для старого пункта меню без статьи: создаём статью с тем же адресом
    def create_page_for_item
      return render_workspace(alert: 'У этого пункта нет адреса статьи', status: :unprocessable_entity) if @item.path.blank?
      return render_workspace(alert: 'Статья для этого пункта уже существует', status: :unprocessable_entity) if page_for_item(@item)
      return render_workspace(alert: 'У вас нет права создавать статьи', status: :forbidden) unless can?('pages_create')

      page = ::Page.new(
        title: @item.title, path: @item.path, lang: @author_page.lang, page_type: 1,
        is_published: true, is_search: true, is_show_parent: true,
        parent_id: @author_page.id, user_id: current_user.id,
      )
      page.save!

      redirect_to edit_admin_page_path(page, welcome: 'author'),
                  notice: 'Статья создана. Напишите текст и нажмите «Готово».'
    rescue ::ActiveRecord::RecordInvalid => e
      render_workspace(alert: "Не удалось создать: #{e.record.errors.full_messages.to_sentence}", status: :unprocessable_entity)
    end

    private

    def set_author_page
      @author_page = ::Page.find(params[:page_id])
    end

    def require_author_page_access
      return if page_owner?(@author_page) || current_user.is_admin?

      deny_access('Это кабинет другого автора')
    end

    def set_item
      @item = ::Menu.where(page_id: @author_page.id).find(params[:id])
    end

    def author_menu_ids
      @author_menu_ids ||= ::Menu.where(page_id: @author_page.id).pluck(:id)
    end

    def inline_mode?
      params[:mode] == 'inline'
    end

    def workspace_locals(create_only: params[:create] == '1')
      items = ::Menu.all_in_display_order(@author_page.id)
      paths = items.filter_map { _1.path.presence&.downcase }
      pages_by_path = paths.any? ? ::Page.where(path_low: paths).index_by(&:path_low) : {}

      {
        author_page: @author_page,
        items:,
        pages_by_path:,
        by_parent: items.group_by(&:parent_id),
        new_parent_id: params[:parent_id].presence&.to_i,
        inline: inline_mode?,
        create_only:,
      }
    end

    def render_workspace(notice: nil, alert: nil, status: :ok)
      expire_page_cache(@author_page.path, @author_page.lang)

      target = inline_mode? ? 'author_menu_inline' : 'author_workspace'
      feedback = if inline_mode?
                   # в обычном режиме модального окна тост живёт внутри <dialog>,
                   # а на странице достаточно общего контейнера
                   toast_stream(notice || alert, type: notice ? 'notice' : 'alert')
                 else
                   workspace_toast(notice || alert, type: notice ? 'notice' : 'alert')
                 end

      render turbo_stream: [
        turbo_stream.replace(target, partial: 'admin/author_workspace/workspace', locals: workspace_locals),
        feedback,
      ], status:
    end

    # Тост внутри модального окна: глобальный #flash-container оказывается
    # за верхним слоем <dialog> и его не видно.
    def workspace_toast(message, type:)
      turbo_stream.append('author_workspace_flash', partial: 'shared/toast', locals: {type:, message:})
    end

    def create_section(title, parent_id)
      position = ::Menu.next_position(@author_page.id, parent_id)
      menu = ::Menu.new(page_id: @author_page.id, parent_id:, title:, priority: position, position:)
      if menu.save
        render_workspace(notice: "Раздел «#{title}» создан")
      else
        render_workspace(alert: "Не удалось создать раздел: #{menu.errors.full_messages.to_sentence}", status: :unprocessable_entity)
      end
    end

    def create_article(title, parent_id)
      return render_workspace(alert: 'У вас нет права создавать статьи. Напишите администратору сайта.', status: :forbidden) unless can?('pages_create')

      page = ::Page.new(
        title:, lang: @author_page.lang, page_type: 1,
        is_published: true, is_search: true, is_show_parent: true,
        parent_id: @author_page.id, user_id: current_user.id,
      )

      ::ActiveRecord::Base.transaction do
        page.save!
        position = ::Menu.next_position(@author_page.id, parent_id)
        ::Menu.create!(page_id: @author_page.id, parent_id:, title:, path: page.path, priority: position, position:)
      end

      expire_page_cache(@author_page.path, @author_page.lang)
      redirect_to edit_admin_page_path(page, welcome: 'author'),
                  notice: 'Статья создана. Напишите текст и нажмите «Готово».'
    rescue ::ActiveRecord::RecordInvalid => e
      render_workspace(alert: "Не удалось создать статью: #{e.record.errors.full_messages.to_sentence}", status: :unprocessable_entity)
    end

    def page_for_item(item)
      return nil if item.path.blank?

      ::Page.find_by(path_low: item.path.downcase)
    end

    def can_manage_page?(page)
      page.owned_by?(current_user) || current_user.is_admin?
    end

    def siblings_of(parent_id, exclude: nil)
      items = ::Menu.siblings_in_display_order(@author_page.id, parent_id)
      items = items.reject { |item| item.id == exclude.id } if exclude
      items
    end

    def renumber!(items)
      items.each_with_index do |item, index|
        item.update_columns(position: index, priority: index) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def move_by_offset(offset)
      siblings = siblings_of(@item.parent_id)
      index = siblings.index(@item)
      new_index = index && index + offset
      if new_index.nil? || new_index.negative? || new_index >= siblings.size
        return render_workspace(alert: 'Дальше перемещать некуда', status: :unprocessable_entity)
      end

      siblings[index], siblings[new_index] = siblings[new_index], siblings[index]
      renumber!(siblings)
      render_workspace(notice: 'Порядок обновлён')
    end

    def indent_item
      siblings = siblings_of(@item.parent_id)
      index = siblings.index(@item)
      return render_workspace(alert: 'Вложить можно только в пункт, который стоит выше', status: :unprocessable_entity) if index.nil? || index.zero?

      new_parent = siblings[index - 1]
      return render_workspace(alert: 'Нельзя вложить пункт в самого себя', status: :unprocessable_entity) if new_parent.id == @item.id

      position = ::Menu.next_position(@author_page.id, new_parent.id)
      @item.update!(parent_id: new_parent.id, priority: position, position:)
      renumber!(siblings_of(new_parent.id))
      render_workspace(notice: "«#{@item.title}» теперь внутри «#{new_parent.title}»")
    end

    def outdent_item
      return render_workspace(alert: 'Пункт уже на верхнем уровне', status: :unprocessable_entity) if @item.parent_id.blank?

      parent = ::Menu.where(page_id: @author_page.id).find_by(id: @item.parent_id)
      return render_workspace(alert: 'Родительский раздел не найден', status: :unprocessable_entity) if parent.nil?

      grandparent_id = parent.parent_id
      ordered = siblings_of(grandparent_id, exclude: @item)
      parent_index = ordered.index(parent)
      return render_workspace(alert: 'Не удалось найти место для переноса', status: :unprocessable_entity) if parent_index.nil?

      @item.update_columns(parent_id: grandparent_id, priority: parent_index + 1, position: parent_index + 1) # rubocop:disable Rails/SkipsModelValidations
      ordered.insert(parent_index + 1, @item)
      renumber!(ordered)
      render_workspace(notice: "«#{@item.title}» вынесен на уровень выше")
    end

    def move_relative_to(target_id, position)
      target = ::Menu.where(page_id: @author_page.id).find_by(id: target_id)
      return render_workspace(alert: 'Пункт, на который вы перетащили, не найден', status: :unprocessable_entity) if target.nil?
      return render_workspace(alert: 'Нельзя переместить пункт в самого себя', status: :unprocessable_entity) if target.id == @item.id
      return render_workspace(alert: 'Нельзя переместить раздел внутрь собственного подпункта', status: :unprocessable_entity) if descendant_ids(@item).include?(target.id)

      new_parent_id = target.parent_id
      ordered = siblings_of(new_parent_id, exclude: @item)
      target_index = ordered.index(target)
      return render_workspace(alert: 'Не удалось определить место', status: :unprocessable_entity) if target_index.nil?

      target_index += 1 if position == 'after'

      @item.update_columns(parent_id: new_parent_id) # rubocop:disable Rails/SkipsModelValidations
      ordered.insert(target_index, @item)
      renumber!(ordered)
      render_workspace(notice: 'Порядок обновлён')
    end

    def descendant_ids(item)
      result = []
      queue = [item.id]
      until queue.empty?
        children = ::Menu.where(page_id: @author_page.id, parent_id: queue.shift).pluck(:id)
        result.concat(children)
        queue.concat(children)
      end
      result
    end
  end
end
