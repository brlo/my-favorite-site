class AddArabicSearchNormalization < ActiveRecord::Migration[7.1]
  # Арабский текст в Библии идёт с огласовками, а ищут его без них. PGroonga
  # сравнивает слова как есть, поэтому рядом с text_search/content храним
  # нормализованную копию (см. ArabicSearchNormalizer) и индексируем её.
  def up
    add_column :verses, :text_search_ar, :text
    add_column :page_paragraphs, :content_ar, :text

    backfill

    add_index :verses, :text_search_ar,
      using: :pgroonga,
      where: "lang = 'ar'",
      name: 'idx_verses_text_search_arabic'
    add_index :page_paragraphs, :content_ar,
      using: :pgroonga,
      where: "lang = 'ar'",
      name: 'idx_page_paragraphs_content_arabic'
  end

  def down
    remove_index :verses, name: 'idx_verses_text_search_arabic'
    remove_index :page_paragraphs, name: 'idx_page_paragraphs_content_arabic'
    remove_column :verses, :text_search_ar
    remove_column :page_paragraphs, :content_ar
  end

  private

  # Правила те же, что в ArabicSearchNormalizer: снять огласовки, татвиль и
  # унифицировать варианты букв. Одним UPDATE — меньше WAL, чем по строке из Rails.
  def backfill
    say_with_time 'Арабские стихи: нормализация для поиска' do
      execute <<~'SQL'
        UPDATE verses
        SET text_search_ar = translate(
          regexp_replace(coalesce(text_search, ''), '[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]', '', 'g'),
          'أإآٱىة', 'اااايه'
        )
        WHERE lang = 'ar'
      SQL
    end

    say_with_time 'Арабские статьи: нормализация для поиска' do
      execute <<~'SQL'
        UPDATE page_paragraphs
        SET content_ar = translate(
          regexp_replace(coalesce(content, ''), '[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]', '', 'g'),
          'أإآٱىة', 'اااايه'
        )
        WHERE lang = 'ar'
      SQL
    end
  end
end
