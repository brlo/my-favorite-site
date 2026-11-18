class Tag < ApplicationRecord
  # Тег статьи. name — каноническое (русское) имя, names — переводы имени ({"en" => "..."}),
  # slug — латиница для адреса /{locale}/tags/{slug}.
  # Теги привязываются к статьям через Tagging: один набор на всю группу переводов статьи.

  has_many :taggings, dependent: :destroy
  has_many :pages, through: :taggings

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :normalize_name
  # slug генерируем только если не задан: при переименовании адрес /tags/{slug} не должен плыть
  before_validation :generate_slug, if: -> { slug.blank? }

  # транслитерация ru -> lat для адреса
  TRANSLIT = {
    'а' => 'a', 'б' => 'b', 'в' => 'v', 'г' => 'g', 'д' => 'd', 'е' => 'e', 'ё' => 'e', 'ж' => 'zh',
    'з' => 'z', 'и' => 'i', 'й' => 'j', 'к' => 'k', 'л' => 'l', 'м' => 'm', 'н' => 'n', 'о' => 'o',
    'п' => 'p', 'р' => 'r', 'с' => 's', 'т' => 't', 'у' => 'u', 'ф' => 'f', 'х' => 'h', 'ц' => 'ts',
    'ч' => 'ch', 'ш' => 'sh', 'щ' => 'sch', 'ъ' => '', 'ы' => 'y', 'ь' => '', 'э' => 'e', 'ю' => 'yu',
    'я' => 'ya',
  }.freeze

  # «Таинство веры» -> «tainstvo-very»
  def self.slug_from(name)
    slug = name.to_s.downcase.chars.map { |char| TRANSLIT[char] || char }.join
      .gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
    slug.presence || 'tag'
  end

  # найти тег по имени или создать (для поля тегов в форме статьи)
  def self.find_or_create_by_name!(name)
    normalized = name.to_s.gsub(/\s+/, ' ').strip
    find_by(name: normalized) || create!(name: normalized)
  end

  # имя тега на языке lang: перевод из names, иначе каноническое имя
  def name_for(lang)
    names&.dig(lang.to_s).presence || name
  end

  private

  def normalize_name
    self.name = name.to_s.gsub(/\s+/, ' ').strip
  end

  def generate_slug
    base = self.class.slug_from(name)
    candidate = base
    suffix = 2
    while self.class.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    self.slug = candidate
  end
end
