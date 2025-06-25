module Api
  class ImagesController < ApiApplicationController
    before_action :reject_by_read_privs
    before_action :reject_by_update_privs, only: [:create, :update, :destroy]

    def list
      @imgs = Image.order_by(c_at: :desc).limit(100)

      term = params[:term].to_s
      if term.present? && term.length > 2
        term = term.gsub(/[^[[:alnum:]]\s]/, '')
        @imgs = @imgs.where(title: /.*#{term}.*/i)
      end

      render(
        json: {
          'success': 'ok',
          'items': @imgs.map {
              {
                id: _1.id.to_s,
                title: _1.title,
                urls: _1.simple.urls,
              }
          },
        },
        status: :ok,
      )
    end

    def create
      @img = ::Image.new()
      @img.title = params[:title]
      @img.simple = params[:file]
      # u.simple.url # => '/url/to/file.png'
      # u.simple.current_path # => 'path/to/file.png'
      # u.simple_identifier # => 'file.png'
      if @img.save
        render(json: {
          'success': 'ok',
          item: {
            id: @img.id.to_s,
            title: @img.title.to_s,
            urls: @img.simple.urls,
          },
        }, status: :ok)
      else
        render(json: @img.errors, status: :unprocessable_entity)
      end
    end

    def destroy
      @img = ::Image.find(params[:id]) || not_found!()
      if @img.destroy!
        render(json: {'success': 'ok'}, status: :ok)
      else
        render json: @img.errors, status: :unprocessable_entity
      end
    end

    def update
      @img = ::Image.find(params[:id]) || not_found!()
      @img.title = params[:title]

      if @img.save
        render(json: {'success': 'ok', item: @img.simple.urls}, status: :ok)
      else
        render(json: @img.errors, status: :unprocessable_entity)
      end
    end

    private

    def success_response
      {'success': 'ok'}
    end

    def reject_by_read_privs;    ability?('gallery_read'); end
    def reject_by_update_privs
      ability?('gallery_write') #||
      #(ability?('menus_self_update') { @page&.user_id == ::Current.user.id })
    end
  end
end
