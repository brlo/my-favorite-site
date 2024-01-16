module Api
  class MergeRequestsController < ApiApplicationController
    before_action :reject_by_read_privs
    before_action :reject_by_create_privs, only: [:create]
    before_action :reject_by_update_privs, only: [:update]
    before_action :reject_by_destroy_privs, only: [:destroy]

    def list
      @mrs = ::MergeRequest.includes(:user).only(
        :id, :user_id, :page_id, :minus_i, :plus_i, :is_merged, :c_at, :u_at,
        :is_merged, :action_at
      ).order_by(updated_at: -1).limit(20)

      @mrs = @mrs.where(page_id: params[:page_id]) if params[:page_id].present?
      @mrs = @mrs.where(is_merged: params[:is_merged]) if params.key?(:is_merged)
      # указанный пользователем лимит, но не больше 100
      @mrs = @mrs.limit([params[:limit].to_i, 100].min) if params[:limit].present?
      @mrs = @mrs.to_a

      page_ids = @mrs.pluck(:p_id)
      pages = ::Page.where(:id.in => page_ids).only(:id, :title).to_a
      @pages_by_id = pages.index_by(&:id)
      render :list, status: :ok
    end

    def show
      set_merge_request()
      @page = ::Page.find(@mr.page_id)
      @user = ::User.find(@mr.user_id)
    end

    # POST /merge_requests
    def create
      page = ::Page.find_by!(id: params[:page][:id])
      @mr = ::MergeRequest.new()
      # автор
      @mr.user_id = ::Current.user.id
      # заполняем в @mr все необходимые параметры
      ::DiffService.new(@mr, page).fill_fields_on_new_merge_request(page_params)

      # begin
        if @mr.save
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

    def update
      set_merge_request()

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
      set_merge_request()
      # заполняем все необходимые параметры
      @mr.merge!

      # begin
        if @mr.save
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
      set_merge_request()
      # заполняем все необходимые параметры
      @mr.reject!

      # begin
        if @mr.save
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
      set_merge_request()
      # заполняем все необходимые параметры
      @mr.rebase!

      # begin
        if @mr.save
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
      @mr = ::MergeRequest.find(params[:id])
      raise(::Mongoid::Errors::DocumentNotFound) if @mr.nil?
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

    def reject_by_read_privs;    ability?('mrs_read'); end
    def reject_by_create_privs;  ability?('mrs_create'); end
    def reject_by_update_privs;  ability?('mrs_update'); end
    def reject_by_destroy_privs; ability?('mrs_destroy'); end
  end
end
