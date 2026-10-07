class DedupeBibleReferences < ActiveRecord::Migration[8.1]
  def up
    # digest — хеш нормализованного фрагмента: одинаковый текст в разных страницах считаем одной цитатой.
    # Заполняется при пересборке (bible_refs:rebuild), у старых записей пока NULL.
    add_column :bible_references, :digest, :string, limit: 32

    # Одна и та же ссылка в одном труде повторяется — оставляем только первое упоминание
    execute <<~SQL
      DELETE FROM bible_references a
      USING bible_references b
      WHERE a.id > b.id
        AND a.page_id = b.page_id AND a.book_code = b.book_code AND a.chapter = b.chapter
        AND a.verse_start = b.verse_start AND a.verse_end = b.verse_end
    SQL

    remove_index :bible_references, name: 'idx_unique_bible_ref_on_page'
    add_index :bible_references, [:page_id, :book_code, :chapter, :verse_start, :verse_end],
              unique: true, name: 'idx_unique_bible_ref_on_page'
    add_index :bible_references, [:lang, :book_code, :chapter], name: 'idx_bible_refs_on_lang_book_chapter'
    add_index :bible_references, :digest
  end

  def down
    remove_index :bible_references, :digest
    remove_index :bible_references, name: 'idx_bible_refs_on_lang_book_chapter'
    remove_index :bible_references, name: 'idx_unique_bible_ref_on_page'
    add_index :bible_references, [:page_id, :position_in_page, :book_code, :chapter, :verse_start, :verse_end],
              unique: true, name: 'idx_unique_bible_ref_on_page'
    remove_column :bible_references, :digest
  end
end
