class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :translation_reactions do |t|
      t.references :translation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :reaction

      t.timestamps
    end

    add_index :translation_reactions, [:user_id, :translation_id], unique: true
  end
end
