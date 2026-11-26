module Admin
  # Меню статьи-списка (page_type = 4). Ответы — turbo_stream, чтобы не перезагружать форму статьи.
  class MenusController < BaseController
    before_action :set_page
    before_action :set_menu_item, only: %i[update destroy]
    before_action :reject_by_update_privs

    def create
      @menu_item = ::Menu.new(menu_item_params.merge(page_id: @page.id))

      if @menu_item.save
        expire_menu_cache
        @page.touch
        append_to_position_order(@menu_item)
        render_menu(notice: 'Пункт меню добавлен')
      else
        render_menu(alert: "Ошибка: #{@menu_item.errors.full_messages.join(', ')}", status: :unprocessable_entity)
      end
    end

    def update
      expire_menu_cache

      if @menu_item.update(menu_item_params)
        @page.touch
        # ручное изменение приоритета в админке возвращает группу к обычной
        # сортировке по priority (порядок автора из кабинета сбрасывается)
        reset_position_order(@menu_item.parent_id) if @menu_item.saved_change_to_priority?
        # перенос в другую группу: позиция из старой группы больше не подходит
        @menu_item.update_columns(position: nil) if @menu_item.saved_change_to_parent_id? # rubocop:disable Rails/SkipsModelValidations
        render_menu(notice: 'Пункт меню обновлён')
      else
        render_menu(alert: "Ошибка: #{@menu_item.errors.full_messages.join(', ')}", status: :unprocessable_entity)
      end
    end

    def destroy
      if @menu_item.childs.exists?
        render_menu(alert: 'Нельзя удалить пункт меню, у которого есть подпункты. Сначала удалите подпункты.', status: :unprocessable_entity)
        return
      end

      expire_menu_cache
      @menu_item.destroy!
      @page.touch
      render_menu(notice: 'Пункт меню удалён')
    end

    private

    def set_page
      @page = ::Page.find(params[:page_id])
    end

    def set_menu_item
      @menu_item = ::Menu.where(page_id: @page.id).find(params[:id])
    end

    def menu_item_params
      params.require(:menu_item).permit(:title, :path, :parent_id, :priority, :is_gold)
    end

    # Группа упорядочена автором: новый пункт из админки добавляем в конец,
    # чтобы не ломать этот порядок.
    def append_to_position_order(item)
      siblings = ::Menu.where(page_id: @page.id, parent_id: item.parent_id)
      return unless siblings.where.not(position: nil).exists?

      max = siblings.maximum(:position)
      position = max ? max + 1 : 0
      item.update_columns(position:, priority: position) # rubocop:disable Rails/SkipsModelValidations
    end

    # В группе был явный порядок из кабинета автора — сбрасываем его,
    # чтобы ручной приоритет из админки снова работал как раньше.
    def reset_position_order(parent_id)
      ::Menu.where(page_id: @page.id, parent_id:).update_all(position: nil) # rubocop:disable Rails/SkipsModelValidations
    end

    def reject_by_update_privs
      deny_access unless page_owner?(@page) || can?('menus_update')
    end

    def render_menu(notice: nil, alert: nil, status: :ok)
      render turbo_stream: [
        turbo_stream.replace('page_menu', partial: 'admin/menus/menu', locals: { page: @page }),
        toast_stream(notice || alert, type: notice ? 'notice' : 'alert'),
      ], status:
    end

    def expire_menu_cache
      # меню на основной странице (где находится всё меню)
      expire_page_cache(@page.path, @page.lang)

      # соседи по уровню меню тоже показывают это меню
      return if @menu_item&.parent_id.blank?

      ::Menu.where(page_id: @page.id, parent_id: @menu_item.parent_id).where.not(path: [nil, '']).pluck(:path).each do |path|
        expire_page_cache(path, @page.lang)
      end
    end
  end
end
