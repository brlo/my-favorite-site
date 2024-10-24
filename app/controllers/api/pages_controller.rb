module Api
  class PagesController < ApiApplicationController
    before_action :reject_by_read_privs
    before_action :reject_by_create_privs, only: [:create]
    before_action :reject_by_update_privs, only: [:update, :cover]
    before_action :reject_by_destroy_privs, only: [:destroy]

    def list
      # надо бы ещё автора показать
      # TODO:
      # - ДОБАВИТЬ ОТДАЧУ РОДИТЕЛЬСКОЙ СТРАНИЦЫ, ЧТОБЫ БЫЛО ПОНЯТНО О ЧЁМ НАЗВАНИЕ СТАТЬИ ЕСЛИ ОНО КРАТКОЕ
      # - УБРАТЬ ОТ СЮДА УДАЛЁННЫЕ СТАТЬИ, ЧТОБЫ ОНИ НЕ ПОКАЗЫВАЛИСЬ В ПОДСКАЗКАХ, НО ОСТАЛИСЬ НА ГЛАВНОЙ СВОДКЕ И В ПОИСКЕ С МЕТКАМИ
      # - В СВОДКЕ ПОКАЗЫВАТЬ ТОЛЬКО ТЕ ПР, КОТОРЫЕ ЕЩЁ НЕ ПРИНЯТЫ
      # - ПОКАЗАТЬ СЛОВАРЬ ДВОРЕЦКОГО
      # - сделать предложение в 404 создать страницу  (с учётом языка и род. страницы)
      @pages = ::Page.
        includes(:user).
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
        @pages = @pages.where(title: /.*#{term}.*/i)
      end

      # указанный пользователем лимит, но не больше 100
      if params[:limit].present?
        @pages = @pages.limit([params[:limit].to_i, 100].min)
      end

      # страницы
      @pages = @pages.to_a

      # просмотры этих страниц из редиса
      @page_visits = ::PageVisits.visits(@pages.map{|p| p.id.to_s }) if @pages.any?

      render :list, status: :ok
    end

    def show
      set_page()
    end

    # POST /pages or /pages.json
    def create
      @page = ::Page.new(page_params)
      # автор статьи
      @page.user_id = ::Current.user.id

      # begin
        if @page.save
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
      # set_page()
      clear_page_cache()

      # добавим редактора статьи
      @page.add_editor(::Current.user)

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
      set_page()
      clear_page_cache()
      @page.cover = params[:file]
      # u.cover.url # => '/url/to/file.png'
      # u.cover.current_path # => 'path/to/file.png'
      # u.cover_identifier # => 'file.png'
      if @page.save
        render(json: {'success': 'ok', cover: @page.cover.urls}, status: :ok)
      else
        render(json: @page.errors, status: :unprocessable_entity)
      end
    end

    def destroy
      set_page()
      clear_page_cache()

      if @page.update(is_deleted: true)
        render :show, status: :ok
      else
        render json: @page.errors, status: :unprocessable_entity
      end
    end

    def restore
      set_page()
      clear_page_cache()

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
        :id, :created_at, :updated_at, :is_deleted,
      ).permit(
        :is_published,
        :page_type, :edit_mode,
        :title, :title_sub, :meta_desc,
        :path,
        :parent_id,
        :lang, :group_lang_id,
        :body, :references,
        :tags_str, :priority, :audio, :is_search
      )
    end

    def reject_by_read_privs;    ability?('pages_read'); end
    def reject_by_create_privs;  ability?('pages_create'); end

    def reject_by_update_privs
      # подгружаем страницу
      set_page()

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
      # подгружаем страницу
      set_page()

      # удалять может человек с привелегией, или автор с привелегией удалять своё
      ability?('pages_destroy') ||
      (ability?('pages_self_destroy') { @page&.user_id == ::Current.user.id })
    end

    def clear_page_cache
      I18n.available_locales.each { |l|
        expire_page("/#{l}/#{@page.lang}/w/#{@page.path}")
      }
    end
  end
end
