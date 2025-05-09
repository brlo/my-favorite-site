module Api
  class MenusController < ApiApplicationController
    # before_action :reject_by_read_privs
    # before_action :reject_by_update_privs, only: [:create, :update, :destroy]

    def list
      set_page()

      # проверка привелегий
      reject_by_read_privs()

      @menu = @page.menu

      render(json: {'success': 'ok', items: @menu}, status: :ok)
    end

    # POST /menus
    def create
      set_page()
      @menu_item = ::Menu.new(menu_item_params)
      @menu_item.page_id = @page.id

      # проверка привелегий
      reject_by_update_privs()

      clear_page_cache()

      # begin
        if @menu_item.save
          @page.touch
          render(json: {'success': 'ok', item: @menu_item.attrs_for_render}, status: :ok)
        else
          # puts '=======ERRORS======='
          # puts @menu_item.errors.messages.inspect

          render json: @menu_item.errors, status: :unprocessable_entity
        end
      # rescue => e
      #   logger.error e.message
      #   logger.error e.backtrace.join("\n")
      #   raise(e)
      # end
    end

    def update
      set_page()
      set_menu_item()
      @menu_item.page_id = @page.id

      # проверка привелегий
      reject_by_update_privs()

      clear_page_cache()

      # begin
        if @menu_item.update(menu_item_params)
          @page.touch
          render(json: {'success': 'ok', item: @menu_item.attrs_for_render}, status: :ok)
        else
          # puts '=======ERRORS======='
          # puts @page.errors.messages.inspect
          render json: @page.errors, status: :unprocessable_entity
        end
      # rescue => e
        # logger.error e.message
        # logger.error e.backtrace.join("\n")
        # raise(e)
      # end
    end

    def destroy
      set_page()
      set_menu_item()

      # проверка привелегий
      reject_by_update_privs()

      clear_page_cache()

      if @menu_item.childs.exists?
        render json: {errors: ['Нельзя удалить пункт меню, у которого есть подпункты. Сначала нужно удалить подпункты']}, status: 422
      else
        begin
          @menu_item.destroy!
          @page.touch
          render(json: {'success': 'ok', item: @menu_item.attrs_for_render}, status: :ok)
        rescue ActiveRecord::RecordNotDestroyed => error
          render json: {errors: error.record.errors}, status: 422
        end
      end
    end

    private

    def success_response
      {'success': 'ok'}
    end

    def set_page
      @page = ::Page.find(params[:id]) || not_found!()
    end

    def set_menu_item
      @menu_item = ::Menu.find(params[:menu_item_id]) || not_found!()
    end

    def menu_item_params
      params.require(:menu_item).except(:id, :created_at, :updated_at, :page_id).permit(
        :title, :path, :parent_id, :priority, :is_gold,
      )
    end

    def reject_by_read_privs;    ability?('pages_read'); end
    def reject_by_update_privs
      ability?('menus_update') #||
      #(ability?('menus_self_update') { @page&.user_id == ::Current.user.id })
    end

    def clear_page_cache
      # чистим меню на основной странице (где находится всё меню)
      I18n.available_locales.each { |l|
        expire_page("/#{l}/#{@page.lang}/w/#{@page.path}")
      }

      # чистим соседей по уровню меню, если они есть
      if @menu_item.parent_id.present?
        ::Menu.where(page_id: @page.id, parent_id: @menu_item.parent_id).each do |menu|
          I18n.available_locales.each { |l|
            expire_page("/#{l}/#{@page.lang}/w/#{menu.path}")
          }
        end
      end
    end

    def page_owner?
      if @page.present?
        ::Current.user.pages_owner.to_a.include?(@page.id.to_s) ||
        ::Current.user.pages_owner.to_a.include?(@page.p_id.to_s)
      end
    end
  end
end
