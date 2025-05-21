module Api
  class MergeRequestsController < ApiApplicationController
    # прежде чем реджектить по привелегиям, надо сначала задать страницу
    before_action :set_merge_request, only: [:show, :update, :merge, :reject, :rebase]
    before_action :clear_page_cache, only: [:merge]
    # теперь реджектим
    before_action :reject_by_read_privs
    before_action :reject_by_create_privs, only: [:create]
    before_action :reject_by_update_privs, only: [:update]
    before_action :reject_by_destroy_privs, only: [:destroy]
    before_action :reject_by_merge_privs, only: [:merge]
    before_action :reject_by_rebase_privs, only: [:rebase]
    before_action :reject_by_reject_privs, only: [:reject]

    def list
      @mrs = ::MergeRequest.includes(:user).only(
        :id, :user_id, :page_id, :is_merged,
        :plus_i, :minus_i,
        :c_at, :u_at,
        :is_merged, :action_at
      ).order_by(updated_at: -1).limit(20)

      @mrs = @mrs.where(page_id: params[:page_id]) if params[:page_id].present?
      @mrs = @mrs.where(is_merged: params[:is_merged]) if params.key?(:is_merged)
      # указанный пользователем лимит, но не больше 100
      @mrs = @mrs.limit([params[:limit].to_i, 100].min) if params[:limit].present?
      @mrs = @mrs.to_a

      page_ids = @mrs.pluck(:p_id)
      pages = ::Page.where(:id.in => page_ids).only(:id, :title, :is_published, :is_deleted).to_a
      @pages_by_id = pages.index_by(&:id)
      render :list, status: :ok
    end

    def show
      @page = ::Page.find(@mr.page_id)
      @user = ::User.find(@mr.user_id)
    end

    # POST /merge_requests
    def create
      @mr = ::MergeRequest.create_mr(
        user: ::Current.user,
        page_id: params[:page][:id],
        page_params: page_params,
        mr_params: mr_params,
      )

      # begin
        if @mr.save
          render(json: {'success': 'ok', item: @mr.attrs_for_render}, status: :ok)
        else
          # puts '=======ERRORS======='
          # puts @mr.errors.messages.inspect
          render json: @mr&.errors, status: :unprocessable_entity
        end
      # rescue => e
      #   logger.error e.message
      #   logger.error e.backtrace.join("\n")
      #   raise(e)
      # end
    end

    def update
      # # begin
      #   if @mr.update(page_params)
      #     render :show, status: :ok
      #   else
      #     # puts '=======ERRORS======='
      #     # puts @mr.errors.messages.inspect
      #     render json: @mr.errors, status: :unprocessable_entity
      #   end
      # # rescue => e
      # #   logger.error e.message
      # #   logger.error e.backtrace.join("\n")
      # #   raise(e)
      # # end
    end

    # def destroy
    #   set_merge_request()

    #   begin
    #     @mr.destroy!
    #     render json: success_response
    #   rescue ActiveRecord::RecordNotDestroyed => error
    #     render json: {errors: error.record.errors}, status: 422
    #   end
    # end

    # POST /merge_requests/:id/merge
    def merge
      @mr.comment = mr_params[:comment]

      # begin
        if @mr.merge!
          render(json: {'success': 'ok', item: @mr.attrs_for_render}, status: :ok)
        else
          # puts '=======ERRORS======='
          # puts @mr.errors.messages.inspect
          render json: @mr.errors, status: :unprocessable_entity
        end
      # rescue => e
      #   logger.error e.message
      #   logger.error e.backtrace.join("\n")
      #   raise(e)
      # end
    end

    # POST /merge_requests/:id/reject
    def reject
      @mr.comment = mr_params[:comment]

      # begin
        if @mr.reject!
          render(json: {'success': 'ok', item: @mr.attrs_for_render}, status: :ok)
        else
          # puts '=======ERRORS======='
          # puts @mr.errors.messages.inspect
          render json: @mr.errors, status: :unprocessable_entity
        end
      # rescue => e
      #   logger.error e.message
      #   logger.error e.backtrace.join("\n")
      #   raise(e)
      # end
    end

    # POST /merge_requests/:id/rebase
    def rebase
      # begin
        if @mr.rebase!
          render(json: {'success': 'ok', item: @mr.attrs_for_render}, status: :ok)
        else
          # puts '=======ERRORS======='
          # puts @mr.errors.messages.inspect
          render json: @mr.errors, status: :unprocessable_entity
        end
      # rescue => e
      #   logger.error e.message
      #   logger.error e.backtrace.join("\n")
      #   raise(e)
      # end
    end

    private

    def success_response
      {'success': 'ok'}
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_merge_request
      @mr = ::MergeRequest.find(params[:id]) || not_found!()
    end

    # Only allow a list of trusted parameters through.
    def mr_params
      # permit docs: https://apidock.com/rails/ActionController/Parameters/permit
      _p = params.permit(mr: [:comment])
      _p[:mr] || {}
    end

    def page_params
      params.require(:page).except(:id, :created_at, :updated_at, :is_deleted).permit(
        :is_published, :edit_mode,
        :page_type, :title, :title_sub, :meta_desc,
        :path,
        :parent_id,
        :lang, :group_lang_id,
        :body, :references,
        :tags_str, :priority, :audio,
      )
    end

    def reject_by_read_privs;    ability?('mrs_read'); end
    def reject_by_create_privs;  ability?('mrs_create'); end
    def reject_by_update_privs;  ability?('mrs_update'); end

    def reject_by_merge_privs;
      return if page_owner?()
      ability?('mrs_merge')
    end

    def reject_by_rebase_privs;
      return if page_owner?()
      ability?('mrs_merge')
    end

    def reject_by_reject_privs
      # можно хозяину
      return if page_owner?()
      # можно, если пользователь отменёет свой MR
      return if @mr&.user_id == ::Current.user.id
      ability?('mrs_reject')
      # (ability?('mrs_self_reject') { @mr&.user_id == ::Current.user.id })
    end

    def reject_by_destroy_privs; ability?('mrs_destroy'); end

    def clear_page_cache
      @page = @mr.page
      I18n.available_locales.each { |l|
        expire_page("/#{l}/#{@page.lang}/w/#{@page.path}")
      }
    end

    def page_owner?
      pg = @mr&.page
      if pg.present?
        ::Current.user.pages_owner.to_a.include?(pg.id.to_s) ||
        ::Current.user.pages_owner.to_a.include?(pg.p_id.to_s)
      end
    end
  end
end
