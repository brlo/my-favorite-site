module Api
  class TranslationProjectsController < ApiApplicationController
    before_action :set_translation_project, only: [:show, :destroy]
    # before_action :reject_by_read_privs, only: [:index, :show]
    # before_action :reject_by_update_priv, only: [:update]
    before_action :reject_by_destroy_priv, only: [:destroy]

    # GET /api/translation_projects
    def index
      @projects = ::TranslationProject.last(20)

      formatted_projects =
      @projects.map do |tp|
        {
          id: tp.id.to_s,
          title: tp.title,
          source_langs: tp.source_langs,
        }
      end

      render json: {
        success: 'ok',
        items: formatted_projects,
      }
    end

    # GET /api/translation_projects/:translation_project_id
    def show
      tp = @translation_project

      render json: {
        success: 'ok',
        item: {
          id: tp.id.to_s,
          title: tp.title,
          description: tp.description,
          source_langs: tp.source_langs,
        }
      }
    end

    # DELETE /api/translation_projects/:translation_project_id
    def destroy
      @translation_project.destroy!
      render :show, status: :ok
    end

    private

    def set_translation_project
      @translation_project = ::TranslationProject.find(params[:translation_project_id])
    end

    def reject_by_read_privs
      # Базовая проверка прав на чтение документа
      ability?('translations_read')
    end

    def reject_by_destroy_priv
      if ::Current.user.is_admin != true
        render json: {success: 'fail', errors: 'У вас нет доступа к этому действию.'}, status: 401
      end
    end
  end
end
