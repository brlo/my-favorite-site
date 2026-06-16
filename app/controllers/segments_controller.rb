class SegmentsController < ApplicationController
  # before_action :require_login
  before_action :set_project
  before_action :set_segment, only: %w[show]

  # def index
  #   @source_texts = @project.segemnts
  #   @source_texts.where(lang: params[:lang]) if params[:lang]
  # end

  private

  def set_project
    @project = TranslationProject.find(params[:translation_project_id])
  end

  def set_segment
    @segment = @project.segments.by_address(
      ch: params[:chapter].to_i,
      p: params[:paragraph].to_i,
      l: params[:line].presence&.to_i
    ).first!
  end
end
