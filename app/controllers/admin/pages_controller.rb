module Admin
  class PagesController < BaseController
    # поля, которые может менять любой, кто может редактировать статью
    BASIC_FIELDS = %i[title title_sub body references is_published].freeze
    # служебные поля, видны и доступны только с привилегией super
    SUPER_FIELDS = %i[
      page_type edit_mode path parent_id lang group_lang_id meta_desc audio
      is_search is_bibleox is_past period_start period_end is_menu_icons is_show_parent
    ].freeze
    # поля, которые приходят предзаполненными из ссылки «создать страницу» (404 на сайте)
    PREFILL_FIELDS = %i[path parent_id lang].freeze

    before_action :set_page, except: %i[index new create]
    before_action :reject_by_read_privs, only: %i[index edit]
    before_action :reject_by_create_privs, only: %i[new create]
    before_action :reject_by_update_privs, only: %i[update cover remove_cover pdf remove_pdf]
    before_action :reject_by_destroy_privs, only: %i[destroy]

    def index
      @term = params[:term].to_s.strip
      @pages = ::Page.select(:id, :title, :path, :is_published, :is_deleted, :lang, :parent_id, :user_id, :updated_at)
        .order(updated_at: :desc)
        .page(params[:page]).per(30)

      # хозяева страниц без общей привилегии видят только свои страницы
      unless can?('pages_read')
        owner_ids = current_user.pages_owner.to_a
        @pages = @pages.where(id: owner_ids).or(@pages.where(parent_id: owner_ids))
      end

      if @term.length > 2
        @pages = @pages.where('title ILIKE ?', "%#{::Page.sanitize_sql_like(@term)}%")
      end

      list = @pages.to_a
      p_ids = list.map(&:parent_id).compact.uniq
      @parent_titles = p_ids.any? ? ::Page.where(id: p_ids).pluck(:id, :title).to_h : {}
      @page_visits = list.any? ? ::PageVisits.visits(list.map(&:id)) : {}
    end

    def new
      @page = ::Page.new(
        page_type: 1,
        is_published: true,
        is_search: true,
        is_show_parent: true,
        title: params[:page_title],
        path: params[:page_path],
        lang: params[:lang].presence || 'ru',
        parent_id: params[:parent_id],
        links: [],
      )
      @menu_id = params[:menu_id]
      set_page_parent
    end

    def create
      @page = ::Page.new(page_params(PREFILL_FIELDS))
      @page.user_id = current_user.id
      @page.links = links_param
      @menu_id = params.dig(:page, :menu_id).presence
      set_page_parent

      if @page.save
        link_created_page_to_menu
        redirect_to edit_admin_page_path(@page), notice: 'Статья создана'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      expire_page_cache(@page.path, @page.lang)
      @page.add_editor(current_user)
      @page.links = links_param

      if @page.update(page_params)
        redirect_to edit_admin_page_path(@page), notice: 'Статья сохранена'
      else
        flash.now[:alert] = 'Не удалось сохранить статью'
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      expire_page_cache(@page.path, @page.lang)

      # удаляем ссылки в меню на эту удаляемую страницу (только в меню страниц того же языка)
      ::Menu.where(path: @page.path).each do |m|
        m.update(path: nil) if ::Page.where(id: m.page_id).pick(:lang) == @page.lang
      end

      @page.destroy!
      redirect_to admin_pages_path, notice: "Статья «#{@page.title}» удалена", status: :see_other
    end

    def cover
      expire_page_cache(@page.path, @page.lang)
      @page.cover = params.dig(:page, :cover)

      if @page.save
        render_cover(notice: 'Изображение для шапки загружено')
      else
        render_cover(alert: "Не удалось загрузить: #{@page.errors.full_messages.join(', ')}")
      end
    end

    def remove_cover
      expire_page_cache(@page.path, @page.lang)
      @page.remove_cover = true
      @page.save!
      render_cover(notice: 'Изображение для шапки удалено')
    end

    def pdf
      file = params.dig(:page, :pdf)

      # content_type присылает клиент, поэтому дополнительно проверяем сигнатуру файла
      is_pdf = file.respond_to?(:read) && file.content_type == 'application/pdf' && file.read(5) == '%PDF-'

      if is_pdf
        file.rewind
        File.binwrite(Rails.root.join('public', 's', 'page_pdfs', "#{@page.id}.pdf"), file.read)
        render_pdf(notice: 'PDF-файл загружен')
      else
        render_pdf(alert: 'Неверный файл. Ожидается PDF.')
      end
    end

    def remove_pdf
      @page.remove_pdf!
      render_pdf(notice: 'PDF-файл удалён')
    end

    private

    def set_page
      @page = ::Page.find(params[:id])
    end

    def page_params(extra_fields = [])
      fields = BASIC_FIELDS + extra_fields
      fields += SUPER_FIELDS if super_user?
      # links и параметры меню разбираются отдельно (links_param, link_created_page_to_menu)
      params.require(:page).except(:links, :menu_id, :menu_category, :menu_item_name).permit(*fields.uniq)
    end

    # строки формы [{title:, path:}] → [[title, path]]
    def links_param
      params.dig(:page, :links).to_a.filter_map do |link|
        title, path = link[:title].to_s.strip, link[:path].to_s.strip
        [title, path] if title.present? || path.present?
      end
    end

    def render_cover(notice: nil, alert: nil)
      render turbo_stream: [
        turbo_stream.replace('page_cover', partial: 'admin/pages/cover', locals: { page: @page }),
        toast_stream(notice || alert, type: notice ? 'notice' : 'alert'),
      ]
    end

    def render_pdf(notice: nil, alert: nil)
      render turbo_stream: [
        turbo_stream.replace('page_pdf', partial: 'admin/pages/pdf', locals: { page: @page }),
        toast_stream(notice || alert, type: notice ? 'notice' : 'alert'),
      ]
    end

    # Особая логика для тех, кто является хозяином единственной страницы.
    # Создаваемым ими страницам принудительно выставляется эта единственная страница в качестве родителя.
    def set_page_parent
      owner_ids = current_user.pages_owner.to_a
      @page.parent_id = owner_ids.first if owner_ids.size == 1
    end

    # После создания страницы связываем её с меню родительской страницы
    def link_created_page_to_menu
      if @menu_id
        # Страницу создали по клику на ещё не существующую ссылку в меню (через 404 на сайте).
        # Прописываем path новой страницы в этот пункт меню, если пользователь может менять это меню.
        menu = ::Menu.find_by(id: @menu_id)
        menu_page = menu && ::Page.find_by(id: menu.page_id)
        if menu_page && (can?('menus_update') || page_owner?(menu_page))
          menu.update(path: @page.path)
        end
        return
      end

      # Если указан только родитель-список, то сами создаём ему пункт меню, ведущий на новую страницу.
      # Даже если ничего не указали, в родительской странице должен появиться пункт меню, а там уже хозяин его распределит.
      return unless @page.parent&.is_page_menu?

      parent_menu_item = nil
      if (category = params.dig(:page, :menu_category).presence)
        parent_menu_item = ::Menu.find_or_create_by!(page_id: @page.parent_id, title: category)
      end

      menu_title = params.dig(:page, :menu_item_name).presence || @page.title
      # если в названии меню только цифра, то приоритет меню тоже равен этой цифре
      # (удобно, когда автоматически создаётся много частей одной книги)
      new_item = ::Menu.create!(
        page_id: @page.parent_id,
        parent_id: parent_menu_item&.id,
        title: menu_title,
        path: @page.path,
        priority: menu_title.match?(/\A\d+\z/) ? menu_title.to_i : 0,
      )

      # Если название статьи заканчивается на #1, то создаём ещё подпункт «1», ведущий туда же.
      # Следующие части (#2, #3...) уже не потребуют такой обработки.
      if @page.title.to_s.match?(/#1\z/)
        ::Menu.create!(page_id: @page.parent_id, parent_id: new_item.id, title: '1', path: @page.path, priority: 1)
      end
    end

    def reject_by_read_privs
      return if action_name == 'index' && current_user.pages_owner.present?
      return if page_owner?(@page) # хозяину страницы можно всё
      require_priv('pages_read')
    end

    def reject_by_create_privs
      require_priv('pages_create')
    end

    def reject_by_update_privs
      deny_access unless page_editable?(@page)
    end

    def reject_by_destroy_privs
      deny_access unless page_destroyable?(@page)
    end

    def page_destroyable?(page)
      page_owner?(page) || can?('pages_destroy') || (can?('pages_self_destroy') && page.user_id == current_user.id)
    end
    helper_method :page_destroyable?

    def page_editable?(page)
      page.editable_by?(current_user)
    end
    helper_method :page_editable?
  end
end
