class CreateBibleReferences < ActiveRecord::Migration[8.0]
  def change
    create_table :bible_references do |t|
      t.references :page,             null: false, foreign_key: true
      t.string     :lang,             null: false, limit: 10
      t.string     :book_code,        null: false, limit: 20
      t.integer    :chapter,          null: false
      t.integer    :verse_start,      null: false
      t.integer    :verse_end,        null: false
      t.text       :context_before,                limit: 500
      t.integer    :position_in_page, null: false # индекс символа начала ссылки
      t.timestamps
    end

    # Уникальность для safe upsert
    # t.index [:page_id, :book_code, :chapter, :verse_start, :verse_end],
    #         unique: true,
    #         name: 'idx_unique_bible_ref_on_page'
    # t.index [:book_code, :chapter, :verse_start]
    ActiveRecord::Migration.add_index :bible_references, [:lang, :book_code, :chapter, :verse_start, :verse_end]
  end
end
