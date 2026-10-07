# Упоминание стихов Писания в труде святого отца (страница с is_past).
# По этим записям строится карта цитирования на страницах Библии.
class BibleReference < ApplicationRecord
  belongs_to :page
  belongs_to :author_page, class_name: 'Page', optional: true

  validates :book_code, :chapter, :verse_start, :verse_end, presence: true

  scope :in_context, ->(book, chapter, verse) do
    where(book_code: book, chapter: chapter, verse_start: ..verse, verse_end: verse..)
  end

  scope :for_lang, ->(lang) { where(lang: lang) }

  # Одинаковый текст фрагмента (например, один труд лежит в двух местах) — одна цитата
  def self.digest_for(snippet)
    Digest::MD5.hexdigest(snippet.to_s.downcase.gsub(/[^\p{L}\p{N}]/, ''))
  end

  # Оставляет по одной записи на уникальный фрагмент (для записей без digest — сама запись)
  def self.uniq_by_digest(refs)
    refs.uniq { |r| r.digest || r.id }
  end

  # { номер_стиха => сколько раз упомянут } для главы, только труды на языке lang
  def self.verse_counts(book, chapter, lang)
    Rails.cache.fetch("bible_refs/verses/#{lang}/#{book}/#{chapter}", expires_in: 1.hour) do
      counts = Hash.new(0)
      rows = for_lang(lang).where(book_code: book, chapter: chapter).pluck(:verse_start, :verse_end, :digest, :id)
      rows.uniq { |from, to, digest, id| [from, to, digest || id] }.each do |from, to, _, _|
        (from..to).each { |v| counts[v] += 1 }
      end
      counts
    end
  end

  # Уровень «жара» 0..1 относительно остальных стихов главы: минимум — холодный, максимум — горячий.
  # Если разброс мал (максимум близок к минимуму), спектр сжимается и все линии остаются холодными.
  def self.heat(count, min, max)
    return 0.0 if max.to_i <= min.to_i
    spread = [Math.log(max.to_f / min) / Math.log(8), 1.0].min
    (Math.log(count.to_f / min) / Math.log(max.to_f / min) * spread).clamp(0.0, 1.0).round(2)
  end
end
