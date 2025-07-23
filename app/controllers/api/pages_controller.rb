module Api
  class PagesController < ApiApplicationController
    # прежде чем реджектить по привелегиям, надо сначала задать страницу
    before_action :set_page, only: [:show, :update, :cover, :destroy, :restore]
    # теперь реджектим
    before_action :reject_by_read_privs, only: [:list, :show]
    before_action :reject_by_create_privs, only: [:create]
    before_action :reject_by_update_privs, only: [:update, :cover]
    before_action :reject_by_destroy_privs, only: [:destroy, :restore]

    # сбрасываем кэш до обновления страницы
    before_action :clear_page_cache, only: [:update, :cover, :destroy, :restore]

    def list
      # TODO:
      # - В СВОДКЕ ПОКАЗЫВАТЬ ТОЛЬКО ТЕ ПР, КОТОРЫЕ ЕЩЁ НЕ ПРИНЯТЫ
      @pages = ::Page.
        only(
          :id, :title, :path, :is_published, :is_deleted, :page_type,
          :edit_mode, :lang, :group_lang_id, :user_id, :parent_id,
          :c_at, :u_at
        ).
        limit(20).
        order_by(updated_at: -1)
        # where(:is_deleted.ne => true)

      term = params[:term].to_s
      if term.present? && term.length > 2
        term = term.gsub(/[^[[:alnum:]]\s]/, '')
        # @pages = @pages.where(title: /.*#{term}.*/i)
        # regex-поиск вместо полнотекстового
        @pages = @pages.where(:$text => { :$search => term })
      end

      # указанный пользователем лимит, но не больше 100
      if params[:limit].present?
        @pages = @pages.limit([params[:limit].to_i, 100].min)
      end

      # страницы
      @pages = @pages.to_a

      # авторы страниц (пока посчитал излишним в выпадающем списке)
      # u_ids = @pages.pluck(:u_id).uniq.compact
      # @authors = ::User.where(id: u_ids) if u_ids

      # родительские страницы
      p_ids = @pages.pluck(:p_id).uniq.compact
      @parent_pages = ::Page.where(:id.in => p_ids).pluck(:id, :title).to_h if p_ids.any?

      # просмотры этих страниц из редиса
      @page_visits = ::PageVisits.visits(@pages.map{|p| p.id.to_s }) if @pages.any?

      render :list, status: :ok
    end

    def show
      # см. before_action наверху
    end

    # POST /pages or /pages.json
    def create
      @page = ::Page.new(page_params)
      # автор статьи
      @page.user_id = ::Current.user.id

      # Особая логика для тех, кто является хозяином единственной страницы.
      # Создаваемым ими страницам принудительно выставляется эта единственная страница в качестве родителя.
      set_page_parent()

      # параметры не получилось разрешить с массивом массивов внутри links, поэтому так делаю отдельно для links:
      @page.links = params[:page][:links]

      # begin
        if @page.save

          # иногда страницу создают через клик на not-exist ссылку в меню, и попадают через 404 в админку,
          # где предзаполнены некоторые поля, а также записана menu_id, с которой сюда попали.
          # Так вот, если страницу в итоге удалось создать, то надо пойти и записать path этой страницы в menu_id.
          #
          # TODO: Внимание! Тут ведь могут прислать любую ссылку, поэтому надо бы подстраховаться
          # и проверить, может ли пользователь менять это меню!
          menu_id = params.dig(:page, :menu_id)
          if menu_id
            # ! ТУТ СВЯЗЫВАЕМ СТРАНИЦУ С УКАЗАННЫМ В ПАРАМЕТРАХ ЭЛЕМЕНТОМ МЕНЮ.
            menu = ::Menu.find_by(id: menu_id)
            menu.update(path: @page.path)
          else
            # ! ТУТ ПЫТАЕМСЯ СОЗДАТЬ ЭЛЕМЕНТ МЕНЮ ДЛЯ СОЗДАННОЙ СТРАНИЦЫ И НАПОЛНИТЬ КАКИМИ-НИБУДЬ ПАРАМЕТРАМИ.
            #
            # Если указан только родитель, а menu_id не указан, то надо самим сгенерировать элемент меню у родителя
            if @page.parent&.is_page_menu?
              # Если указали для нового элемента меню родительский элемент меню, то либо ищем его, либо создаём:
              parent_menu_item = nil
              menu_category_name = params.dig(:page, :menu_category).presence
              if menu_category_name
                parent_menu_item = ::Menu.find_or_create_by!(
                  page_id: @page.parent_id,
                  title: menu_category_name,
                )
              end

              # создаём сам элемент меню
              new_item = ::Menu.create!(
                page_id: @page.parent_id, # страница-хозяин элемента меню
                parent_id: parent_menu_item&.id, # родительский элемент
                title: params.dig(:page, :menu_item_name).presence || @page.title,
                path: @page.path,
              )
            end
          end

          render :show, status: :ok
        else
          # puts '=======ERRORS======='
          # puts @page.errors.messages.inspect
          render json: @page.errors, status: :unprocessable_entity
        end
      # rescue => e
      #   logger.error e.message
      #   logger.error e.backtrace.join("\n")
      #   raise(e)
      # end
    end

    def update
      # добавим редактора статьи
      @page.add_editor(::Current.user)

      # параметры не получилось разрешить с массивом массивов внутри links, поэтому так делаю отдельно для links:
      @page.links = params[:page][:links]

      # begin
        if @page.update(page_params)
          render :show, status: :ok
        else
          # puts '=======ERRORS======='
          # puts @page.errors.messages.inspect
          render json: @page.errors, status: :unprocessable_entity
        end
      # rescue => e
      #   logger.error e.message
      #   logger.error e.backtrace.join("\n")
      #   raise(e)
      # end
    end

    def cover
      uploaded_file = params[:file]

      # # Проверка доступности временного файла (исправленная версия)
      # unless File.exist?(uploaded_file.tempfile.path)
      #   Rails.logger.error " === Temp file not found: #{e.message}"
      #   return render json: { error: "Temp file not found" }, status: 422
      # end

      # # Проверка размера файла
      # if uploaded_file.tempfile.size.zero?
      #   Rails.logger.error " === File is empty: #{e.message}"
      #   return render json: { error: "File is empty" }, status: 422
      # end

      # # Проверка изображения через MiniMagick
      # begin
      #   image = MiniMagick::Image.open(uploaded_file.tempfile.path)
      #   image.validate!
      # rescue MiniMagick::Error, Errno::ENOENT => e
      #   Rails.logger.error " === Image validation failed: #{e.message}"
      #   return render json: { error: "Invalid image file: #{e.message}" }, status: 422
      # end

      @page.cover = uploaded_file

      # u.cover.url # => '/url/to/file.png'
      # u.cover.current_path # => 'path/to/file.png'
      # u.cover_identifier # => 'file.png'

      if @page.save
        render(json: {'success': 'ok', cover: @page.cover.urls}, status: :ok)
      else
        puts "======================= ERROR =============================="
        puts @page.errors.inspect

        render(json: @page.errors, status: :unprocessable_entity)
      end
    end

    def destroy
      # удаляем ссылки в меню на эту удаляемую страницу
      ::Menu.where(path: @page.path).each do |m|
        # перед стираением адреса в меню, надо убедиться, что мы работаем в той же языковой области.
        # делаем это, сравнивая язык страницы с отрисованым меню, и удаляемой страницы:
        _page = Page.where(id: m.page_id).first
        if _page&.lang == @page.lang
          m.update(path: nil)
        end
      end

      @page.destroy!
      render :show, status: :ok
      # if @page.update(is_deleted: true)
      #   render :show, status: :ok
      # else
      #   render json: @page.errors, status: :unprocessable_entity
      # end
    end

    # Так как теперь страницы удаляются целиком, то этот метод пока что не востребован
    def restore
      if @page.update(is_deleted: false)
        render :show, status: :ok
      else
        render json: @page.errors, status: :unprocessable_entity
      end
    end

    private

    def success_response
      {'success': 'ok'}
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_page
      @page ||= ::Page.find(params[:id]) || not_found!()
    end

    # Only allow a list of trusted parameters through.
    def page_params
      params.require(:page).except(
        :id, :created_at, :updated_at, :is_deleted, :cover, :links,
      ).permit(
        :is_bibleox, :is_menu_icons,
        :is_published,
        :page_type, :edit_mode,
        :title, :title_sub, :meta_desc,
        :path,
        :parent_id,
        :lang, :group_lang_id,
        :body, :references,
        :tags_str, :priority, :audio, :is_search, :is_show_parent, :is_menu_icons
      )
    end

    def reject_by_read_privs
      return if page_owner?() # хозяину страницы можно всё
      ability?('pages_read')
    end

    def reject_by_create_privs
      return if page_owner?() # хозяину страницы можно всё
      ability?('pages_create')
    end

    def reject_by_update_privs
      return if page_owner?() # хозяину страницы можно всё

      is_can =
      case @page.edit_mode.to_i
      when 1
        # только админы
        ::Current.user.is_admin == true
      when 2
        # только модераторы
        ability?('pages_update')
      when 3
        false
        # автор или редакторы (от кого уже принимали MR сюда)
        # и которые не лишены привилегий редактировать свои статьи или статьи где они редакторы
        #(ability?('pages_self_update') { @page&.user_id == ::Current.user.id }) ||
        #(ability?('pages_editor_update') { @page&.editors.to_a.includes?(::Current.user.id) })
      else
        false
      end

      if !is_can
        render json: {success: 'fail', errors: 'У вас нет доступа к этому действию.'}, status: 401
      end
    end

    def reject_by_destroy_privs
      return if page_owner?() # хозяину страницы можно всё

      # удалять может человек с привелегией, или автор с привелегией удалять своё
      ability?('pages_destroy') ||
      (ability?('pages_self_destroy') { @page&.user_id == ::Current.user.id })
    end

    def clear_page_cache
      I18n.available_locales.each { |l|
        expire_page("/#{l}/#{@page.lang}/w/#{@page.path}")
      }
    end

    def page_owner?
      if @page.present?
        ::Current.user.pages_owner.to_a.include?(@page.id.to_s) ||
        ::Current.user.pages_owner.to_a.include?(@page.p_id.to_s)
      end
    end

    # Особая логика для тех, кто является хозяином единственной страницы.
    # Создаваемым ими страницам принудительно выставляется эта единственная страница в качестве родителя.
    def set_page_parent
      return unless @page.present?
      return unless ::Current.user&.pages_owner.is_a?(Array)

      if ::Current.user.pages_owner.size == 1
        @page.p_id = ::Current.user.pages_owner.first
      end
    end
  end
end
