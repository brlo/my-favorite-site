class CreateImages < ActiveRecord::Migration[8.0]
  def change
    create_table :images do |t|
      t.string :title # описание
      t.string :simple # имя файла
      t.bigint :user_id

      t.timestamps null: false
    end
  end
end
