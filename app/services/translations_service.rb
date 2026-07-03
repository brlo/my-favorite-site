class TranslationsService
  class << self
    # ::TranslationsService.group_by_lang_and_sort_by_priority(translations)
    # => {lang => [sorted_tanslations]}
    def group_by_lang_and_sort_by_priority(translations)
      res = translations.group_by(&:lang).transform_values { |translations| sort_by_priority(translations) }
      res
    end

    # ::TranslationsService.sort_by_priority(translations)
    # => [sorted_tanslations]
    def sort_by_priority(translations)
      translations.sort_by { [it.is_approved? ? 0 : 1, -it.vote_score] }
    end
  end
end
