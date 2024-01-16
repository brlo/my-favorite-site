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
          :id, :title, :is_published, :page_type,
          :lang, :group_lang_id, :user_id, :parent_id, :c_at, :u_at
        )

      term = params[:term].to_s
      if term.present? && term.length > 2
        term = term.gsub(/[^[[:alnum:]]\s]/, '')
        @pages = @pages.where(title: /.*#{term}.*/i)
      end

      @pages = @pages.order_by(updated_at: -1).limit(20).to_a
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
      @page = ::Page.find(params[:id])
      raise(::Mongoid::Errors::DocumentNotFound) if @page.nil?
    end

    # Only allow a list of trusted parameters through.
    def page_params
      params.require(:page).except(:id, :created_at, :updated_at).permit(
        :is_published,
        :page_type, :title, :title_sub, :meta_desc,
        :path,
        :parent_id,
        :lang, :group_lang_id,
        :body, :references, :tags_str, :priority,
      )
    end

    def reject_by_read_privs;    ability?('pages_read'); end
    def reject_by_create_privs;  ability?('pages_create'); end
    def reject_by_update_privs;  ability?('pages_update'); end
    def reject_by_destroy_privs; ability?('pages_destroy'); end
  end
end
