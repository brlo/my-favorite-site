class CreateTags < ActiveRecord::Migration[8.1]
  def change
    # Теги статей: name — каноническое (русское) имя, names — переводы имени ({"en" => "..."}),
    # slug — латиница для адресов /{locale}/tags/{slug}
    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.jsonb :names, null: false, default: {}
      t.timestamps
    end
    add_index :tags, :name, unique: true
    add_index :tags, :slug, unique: true

    # Связь тег ↔ статья; тег ставится один раз на всю группу переводов (по одной строке на каждую языковую версию)
    create_table :taggings do |t|
      t.references :page, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.timestamps
    end
    add_index :taggings, [:page_id, :tag_id], unique: true
    add_index :taggings, :tag_id

    # по группе переводов ищем страницу при переключении языка и при синхронизации тегов, индекса не было
    add_index :pages, :group_lang_id
  end
end
