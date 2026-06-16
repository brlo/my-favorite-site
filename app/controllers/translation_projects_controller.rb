class TranslationProjectsController < ApplicationController
  before_action :set_project, only: %w[show edit update destroy import_content result]
  before_action :set_active_menu_item

  before_action :require_login, except: %w[index show result]
  before_action :require_admin, except: %w[index show result]

  def index
    @breadcrumbs = [['Все переводы']]

    @projects = TranslationProject.all # .page(params[:page])
  end

  def show
    @breadcrumbs = [['Все переводы', translation_projects_path(locale: I18n.locale)], [@project.title]]
    @page_title = "Коллективный переод — #{@project.title}"

    @part = params[:part]&.to_i || 1
    @lang_to = params[:lang_to] || ::I18n.locale.to_s

    @all_langs = @project.translations.pluck('distinct lang').sort
    @all_parts = @project.segments.pluck('distinct part').sort

    @segments = @project.segments
      .where(part: @part)
      .includes(translations: :user)
      .order(:chapter, :paragraph, :line)

    @progress_percent = @project.progress_for(part: @part, lang_to: @lang_to)
  end

  def result
    @breadcrumbs = [
      ['Все переводы', translation_projects_path(locale: I18n.locale)],
      [@project.title, translation_project_path(@project)],
      ['Результат перевода']
    ]
    @page_title = "Коллективный переод — #{@project.title}"

    @part = params[:part]&.to_i || 1
    @lang_to = params[:lang_to] || ::I18n.locale.to_s

    @all_langs = @project.translations.pluck('distinct lang').sort
    @all_parts = @project.segments.pluck('distinct part').sort

    @result_html, @references_html = @project.result_for(lang_to: @lang_to, part: @part)
  end

  def new
    @breadcrumbs = [['Все переводы', translation_projects_path(locale: I18n.locale)], "Новый проект перевода"]
    @page_title = "Новый проект перевода"
    @project = TranslationProject.new
  end

  def edit
    @breadcrumbs = [
      ['Все переводы', translation_projects_path(locale: I18n.locale)],
      [@project.title, translation_project_path(@project)],
      ['edit']
    ]
    @page_title = "Редактирование проекта перевода"
  end

  def create
    @project = TranslationProject.new(project_params)
    if @project.save
      redirect_to @project, notice: 'Проект создан'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @project = TranslationProject.new(project_params)
    if @project.save
      redirect_to @project, notice: 'Проект создан'
    else
      render @project, status: :unprocessable_entity
    end
  end

  def destroy
    part = params[:part]
    if part.present?
      @project.segments.where(part: part).destroy_all
      redirect_to translation_project_path(@project), notice: "В проекте удалёна часть #{part}"
    elsif part.blank? && @project.destroy
      redirect_to translation_projects_path, notice: 'Проект удалён'
    else
      render @project, status: :unprocessable_entity
    end
  end

  # Обрабатывает вставку HTML
  def import_content
    html = params[:html_content].to_s.strip
    lang = params[:lang] || 'ru'

    new_part_num = @project.add_part(body: html, lang: lang, part: nil)

    if @project.errors.none?
      redirect_to translation_project_path(@project, lang_to: lang, part: new_part_num)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = TranslationProject.find(params[:id])
  end

  def find_current_segment
    if params[:chapter] && params[:paragraph]
      @project.segments.by_address(
        ch: params[:chapter].to_i,
        p: params[:paragraph].to_i,
        l: params[:line].presence&.to_i
      ).first
    else
      @project.segments.ordered.first
    end
  end

  def project_params
    params.require(:translation_project).permit(:title, :description, source_langs: [])
  end

  def set_active_menu_item
    @current_menu_item = 'translates'
  end
end
