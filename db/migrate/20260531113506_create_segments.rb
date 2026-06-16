class CreateSegments < ActiveRecord::Migration[8.1]
  def change
    create_table :segments do |t|
      # Адресация
      t.integer :part, null: false
      t.integer :chapter, null: false
      t.integer :paragraph, null: false
      t.integer :line

      # Содержание
      t.string :lang
      t.text :text
      t.boolean :is_original, default: false
      t.jsonb :open_tags, default: []
      t.jsonb :close_tags, default: []

      # Связи
      t.references :translation_project, null: false, foreign_key: true
      t.references :source_segment, foreign_key: { to_table: :segments }, null: true

      t.timestamps
    end

    # Индексы для быстрой выборки
    # add_index :segments, [:translation_project_id, :part] # надо, но пока решил не добавлять, пока не допишу код
    add_index :segments, [:translation_project_id, :part, :chapter, :paragraph, :line, :lang]

    add_index :segments, [:translation_project_id, :lang]
  end
end
