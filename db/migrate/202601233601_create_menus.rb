class CreateMenus < ActiveRecord::Migration[8.0]
  def change
    create_table :menus do |t|
      t.bigint :parent_id, index: true
      t.bigint :page_id, null: false, index: true
      t.string :title, null: false
      t.string :path, index: true
      t.boolean :is_gold, default: false
      t.boolean :is_empty, default: false
      t.integer :priority, default: 0

      t.timestamps null: false
    end

    # Внешние ключи (опционально, если вы не используете строгую целостность)
    # add_foreign_key :menus, :menus, column: :parent_id
    # add_foreign_key :menus, :pages, column: :page_id
  end
end
