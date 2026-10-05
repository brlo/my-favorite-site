class ExtendBibleReferencesForCitations < ActiveRecord::Migration[8.1]
  def change
    # author_page_id — страница автора (святого отца), под которой лежит труд
    add_column :bible_references, :author_page_id, :bigint
    # snippet — фрагмент текста вокруг ссылки, для показа в списке цитат
    add_column :bible_references, :snippet, :text

    add_index :bible_references, [:book_code, :chapter, :verse_start, :verse_end],
              name: 'idx_bible_refs_on_book_chapter_verses'
    add_index :bible_references, [:page_id, :position_in_page, :book_code, :chapter, :verse_start, :verse_end],
              unique: true, name: 'idx_unique_bible_ref_on_page'
    add_index :bible_references, :author_page_id
  end
end
