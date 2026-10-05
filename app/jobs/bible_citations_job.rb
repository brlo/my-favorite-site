class BibleCitationsJob < ApplicationJob
  queue_as :default

  def perform(page_id)
    page = ::Page.find_by(id: page_id)
    return unless page
    ::BibleCitationExtractor.call(page)
  end
end
