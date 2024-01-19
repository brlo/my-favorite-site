module Api
  class PagesController < ApiApplicationController
    before_action :reject_by_read_privs
    before_action :reject_by_create_privs, only: [:create]
    before_action :reject_by_update_privs, only: [:update]
    before_action :reject_by_destroy_privs, only: [:destroy]

    def list
      # надо бы ещё автора показать
      @pages = ::Page.
        includes(:user).
        only(
          :id, :title, :path, :is_published, :page_type,
          :lang, :group_lang_id, :user_id, :parent_id, :c_at, :u_at
        ).
        limit(20).
        order_by(updated_at: -1)

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
      set_page()

      # добавим редактора статьи
      @page.editors = @page.editors.to_a | [::Current.user.id]

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

    def destroy
      set_page()

      begin
        @page.destroy!
        render json: success_response
      rescue ActiveRecord::RecordNotDestroyed => error
        render json: {errors: error.record.errors}, status: 422
      end
    end

    private

    def success_response
      {'success': 'ok'}
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_page
      @page = ::Page.find(params[:id]) || not_found!()
    end

    # Only allow a list of trusted parameters through.
    def page_params
      params.require(:page).except(:id, :created_at, :updated_at).permit(
        :is_published,
        :page_type, :title, :title_sub, :meta_desc,
        :path,
        :parent_id,
        :lang, :group_lang_id,
        :body, :tags_str, :priority,
      )
    end

    def reject_by_read_privs;    ability?('pages_read'); end
    def reject_by_create_privs;  ability?('pages_create'); end
    def reject_by_update_privs
      ability?('pages_update') ||
      (ability?('pages_self_update') && @page&.user_id == ::Current.user.id) ||
      (ability?('pages_editor_update') && @page&.editors.to_a.includes?(::Current.user.id))
    end
    def reject_by_destroy_privs
      ability?('pages_destroy') ||
      (ability?('pages_self_destroy') && @page&.user_id == ::Current.user.id)
    end
  end
end
