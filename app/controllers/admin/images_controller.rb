module Admin
  class ImagesController < BaseController
    before_action -> { require_priv('gallery_read') }
    before_action -> { require_priv('gallery_write') }, only: %i[create update destroy]

    def index
      @term = params[:term].to_s.strip
      @images = ::Image.order(id: :desc).page(params[:page]).per(60)
      @images = @images.where('title ILIKE ?', "%#{::Image.sanitize_sql_like(@term)}%") if @term.length > 2
    end

    def create
      image = ::Image.new(title: params.dig(:image, :title), simple: params.dig(:image, :file), user_id: current_user.id)

      if image.save
        redirect_to admin_images_path, notice: 'Картинка загружена'
      else
        redirect_to admin_images_path, alert: "Не удалось загрузить картинку: #{image.errors.full_messages.join(', ')}"
      end
    end

    def update
      image = ::Image.find(params[:id])

      if image.update(title: params.dig(:image, :title))
        render turbo_stream: toast_stream('Название сохранено')
      else
        render turbo_stream: toast_stream(image.errors.full_messages.join(', '), type: 'alert'), status: :unprocessable_entity
      end
    end

    def destroy
      image = ::Image.find(params[:id])
      image.destroy!

      render turbo_stream: [
        turbo_stream.remove(helpers.dom_id(image)),
        toast_stream('Картинка удалена'),
      ]
    end
  end
end
