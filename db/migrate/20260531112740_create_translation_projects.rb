class CreateTranslationProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :translation_projects do |t|
      t.string :title, null: false
      t.text :description
      t.string :source_langs, array: true, default: []
      t.bigint :page_ids, array: true, default: []
      t.timestamps
    end
  end
end
