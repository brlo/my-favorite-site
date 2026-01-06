class CreateBibWords < ActiveRecord::Migration[8.0]
  def change
    create_table :bib_words do |t|
      t.integer :bw_id, null: false
      t.string :word, null: false
      t.string :dict_word
      t.integer :counts, default: 0, null: false
      t.integer :counts_by_lexema, default: 0, null: false
      t.string :lexema
      t.jsonb :info, default: {}, null: false
      t.jsonb :transcriptions, default: {}, null: false
      t.jsonb :translations, default: {}, null: false

      t.timestamps null: false

      # Массив адресов: используем PostgreSQL массив строк
      t.string :addrs, array: true, default: [], null: false
    end

    # Уникальные индексы
    add_index :bib_words, :bw_id, unique: true
    add_index :bib_words, :word, unique: true
    add_index :bib_words, :lexema
  end
end
