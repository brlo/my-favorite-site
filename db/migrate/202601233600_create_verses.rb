class CreateVerses < ActiveRecord::Migration[8.0]
  def up
    create_table :verses do |t|
      t.string :tr_code, null: false
      t.string :lang, null: false
      t.string :address, null: false
      t.boolean :zavet, null: false
      t.integer :book_id, null: false
      t.string :book, null: false
      t.integer :chapter, null: false
      t.integer :line, null: false
      t.text :text, null: false
      t.text :text_search # текст без html-тэгов для подсветки совпадений после поиска
      t.jsonb :data, default: {} # Hash → JSONB

      t.timestamps null: false
    end

    # Индексы
    add_index :verses, [:tr_code, :book]
    add_index :verses, [:tr_code, :zavet]
    add_index :verses, [:tr_code, :book, :chapter]
    add_index :verses, [:tr_code, :book_id, :chapter, :line], unique: true

    # Индекс для полнотекстового поиска (будет обновляться триггером или вручную)
    # https://github.com/Casecommons/pg_search
    add_column :verses, :text_tsvector, :tsvector
    add_index :verses, :text_tsvector, using: :gin
  end

  def down
    drop_table :verses
  end
end
