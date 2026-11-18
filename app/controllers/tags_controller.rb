class TagsController < ApplicationController
  skip_before_action :require_login_and_activation

  PER_PAGE = 30

  def index
    # показываем только теги, у которых есть опубликованные статьи на языке локали
    @tags = ::Tag.joins(taggings: :page)
      .where(pages: { lang: lang, is_published: true, is_deleted: [nil, false] })
      .group('tags.id')
      .select('tags.*, COUNT(*) AS pages_count')
      .order(::Arel.sql('COUNT(*) DESC, tags.name'))

    @page_title = ::I18n.t('tags.title')
    @meta_description = ::I18n.t('tags.meta_description')
    @canonical_url = build_canonical_url('/tags/')
    @current_menu_item = 'links'
  end

  def show
    @tag = ::Tag.find_by!(slug: params[:slug])

    @pages = ::Page.where(is_published: true, is_deleted: [nil, false], lang: lang)
      .joins(:taggings).where(taggings: { tag_id: @tag.id })
      .select(:id, :title, :path, :lang, :updated_at)
      .order(updated_at: :desc).page(params[:page]).per(PER_PAGE)

    # на каких ещё языках есть статьи с этим тегом; показываем только языки, у которых
    # есть своя локаль в адресе (у языков только с контентом — xcl, cop... — локали нет)
    @other_langs = ::Tagging.joins(:page)
      .where(taggings: { tag_id: @tag.id }, pages: { is_published: true, is_deleted: [nil, false] })
      .where.not(pages: { lang: lang }).distinct.pluck('pages.lang')
      .select { |page_lang| ::ALL_LOCALES.key?(page_lang) }

    tag_name = @tag.name_for(lang)
    @breadcrumbs = [[::I18n.t('tags.title'), "/#{lang}/tags"], [tag_name]]
    @page_title = ::I18n.t('tags.tag_page_title', tag: tag_name)
    @meta_description = ::I18n.t('tags.tag_meta_description', tag: tag_name)
    @canonical_url = build_canonical_url("/tags/#{@tag.slug}")
    @current_menu_item = 'links'
  end

  private

  # статьи тега показываем на языке текущей локали интерфейса
  def lang
    ::I18n.locale.to_s
  end
end
