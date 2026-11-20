class CreatePageReactions < ActiveRecord::Migration[8.1]
  # Положительные реакции читателей на статью. Привязка к IP без авторизации:
  # храним только HMAC-дайджест адреса (PageReaction.digest_ip), не сам IP.
  def change
    create_table :page_reactions do |t|
      t.references :page, null: false, foreign_key: true, index: false
      t.string :kind, null: false, default: 'like'
      t.string :ip_digest, null: false
      t.timestamps
    end

    add_index :page_reactions, %i[page_id ip_digest kind], unique: true,
              name: 'index_page_reactions_on_page_ip_kind'
  end
end
