class CreateTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :translations do |t|
      t.text :text, null: false
      t.text :sub_text, null: true # второстепенный текст, универсальное поле. Чаще это будет сноской, а для ссылкок — адресом.
      t.string :lang, null: false
      t.string :source_lang
      t.integer :vote_score, default: 0
      t.jsonb :votes, default: {}
      t.boolean :is_approved, default: false

      t.references :translation_project, null: false, foreign_key: true
      t.references :segment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :translations, :translation_project_id
    add_index :translations, [:segment_id, :lang]
    add_index :translations, :is_approved, where: 'is_approved = true'
  end
end
