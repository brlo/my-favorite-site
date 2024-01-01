module Api
  class PagesController < ApiApplicationController
    def list
      @pages = ::Page.only(:id, :title, :lang, :c_at, :u_at)

      term = params[:term].to_s
      if term.present? && term.length > 2
        term = term.gsub(/[^[[:alnum:]]\s]/, '')
        @pages = @pages.where(title: /.*#{term}.*/i)
      end

      @pages = @pages.order_by(updated_at: -1).limit(100).to_a
      render :list, status: :ok
    end

    def show
      set_page()
    end

    # POST /pages or /pages.json
    def create
      @page = ::Page.new(page_params)

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
        :published,
        :page_type, :title, :title_sub, :meta_desc,
        :path,
        :parent_id,
        :next_id, :next_title,
        :prev_id, :prev_title,
        :lang, :group_lang_id,
        :body, :references, :tags_str, :priority,
      )
    end
  end
end
