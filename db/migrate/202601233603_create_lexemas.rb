class CreateLexemas < ActiveRecord::Migration[8.0]
  def change
    create_table :lexemas do |t|
      t.string :word, null: false
      t.string :lexema
      t.string :lexema_clean
      t.string :transcription
      t.integer :counts, default: 0, null: false
      t.text :xml_doc

      t.timestamps null: false
    end

    # Индексы
    add_index :lexemas, :word
    add_index :lexemas, :lexema
    add_index :lexemas, [:word, :lexema], unique: true
  end
end
