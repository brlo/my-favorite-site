module Api
  class MenusController < ApiApplicationController
    def list
      set_page()
      @tree_menu = @page.tree_menu

      render(json: {'success': 'ok', items: @tree_menu}, status: :ok)
    end

    # POST /menus
    def create
      set_page()
      @menu_item = ::Menu.new(menu_item_params)
      @menu_item.page_id = @page.id

      # begin
        if @menu_item.save
          @tree_menu = @page.tree_menu
          render(json: {'success': 'ok', items: @tree_menu}, status: :ok)
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
      begin
      set_page()
      set_menu_item()
      @menu_item.page_id = @page.id

        if @menu_item.update(menu_item_params)
          @tree_menu = @page.tree_menu
          render(json: {'success': 'ok', items: @tree_menu}, status: :ok)
        else
          puts '=======ERRORS======='
          puts @page.errors.messages.inspect
          render json: @page.errors, status: :unprocessable_entity
        end
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n")
        raise(e)
      end
    end

    def destroy
      set_page()
      set_menu_item()

      if @menu_item.childs.exists?
        render json: {errors: ['Нельзя удалить пункт меню, у которого есть подпункты. Сначала нужно удалить подпункты']}, status: 422
      else
        begin
          @menu_item.destroy!
          @tree_menu = @page.tree_menu
          render(json: {'success': 'ok', items: @tree_menu}, status: :ok)
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
      @page = ::Page.find(params[:id])
      raise(::Mongoid::Errors::DocumentNotFound) if @page.nil?
    end

    def set_menu_item
      @menu_item = ::Menu.find(params[:menu_item_id])
      raise(::Mongoid::Errors::DocumentNotFound) if @menu_item.nil?
    end

    def menu_item_params
      params.require(:menu_item).except(:id, :created_at, :updated_at, :page_id).permit(
        :title, :path, :path_parent, :priority,
      )
    end
  end
end
