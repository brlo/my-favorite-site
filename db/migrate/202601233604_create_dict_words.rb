class CreateDictWords < ActiveRecord::Migration[8.0]
  def change
    create_table :dict_words do |t|
      t.string :dict, null: false
      t.string :word, null: false
      t.string :word_simple, null: false
      t.string :word_simple_no_endings
      t.string :sinonim
      t.string :lexema
      t.string :transcription
      t.string :transcription_lat
      t.string :translation_short
      t.string :translation
      t.string :tag
      t.text :desc

      t.timestamps null: false
    end

    # Индексы
    add_index :dict_words, :dict
    add_index :dict_words, :word_simple
    add_index :dict_words, :tag
  end
end
