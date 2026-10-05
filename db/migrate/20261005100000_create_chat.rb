class CreateChat < ActiveRecord::Migration[8.1]
  def change
    # Комнаты. Пока одна общая, но room_id у сообщений заложен заранее.
    create_table :chat_rooms do |t|
      t.string :slug, null: false
      t.string :title
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end
    add_index :chat_rooms, :slug, unique: true

    # Участник чата: гость, пользователь или бот.
    create_table :chat_members do |t|
      t.string :kind, null: false          # guest | user | bot
      t.string :role, null: false          # admin | moderator | member | guest | bot
      t.references :user, foreign_key: { on_delete: :nullify }, index: { unique: true }
      t.string :guest_token_digest         # sha256 от токена из cookie гостя

      t.string :nickname, null: false
      t.string :bio
      t.string :avatar
      t.string :title                      # титул рядом с ником

      t.string :ui_lang, null: false, default: 'en'
      t.string :landing_url                # страница, с которой начал посещение сайта
      t.string :landing_referrer
      t.datetime :landing_at
      t.string :chat_entry_url             # страница, с которой пришёл в чат

      t.string :ip_hash
      t.datetime :muted_until
      t.datetime :banned_until
      t.datetime :last_seen_at

      t.timestamps
    end
    add_index :chat_members, :guest_token_digest, unique: true
    add_index :chat_members, 'lower(nickname)', unique: true, name: 'index_chat_members_on_lower_nickname'

    create_table :chat_messages do |t|
      t.references :room, null: false, foreign_key: { to_table: :chat_rooms }, index: false
      t.references :member, null: false, foreign_key: { to_table: :chat_members, on_delete: :cascade }
      t.references :reply_to, foreign_key: { to_table: :chat_messages, on_delete: :nullify }, index: false
      t.references :recipient_member, foreign_key: { to_table: :chat_members, on_delete: :cascade }, index: false

      t.string :kind, null: false, default: 'text'           # text | system
      t.string :status, null: false                          # pending | published
      t.string :visibility, null: false, default: 'public'   # public | direct

      t.jsonb :body_json
      t.text :body_html
      t.text :body_text
      t.string :lang, null: false                            # ui_lang автора на момент написания
      t.jsonb :translations, null: false, default: {}        # {"en" => {"html" => ..., "v" => edits_count}}
      t.jsonb :reactions_summary, null: false, default: {}   # {"🙏" => 3}

      t.integer :edits_count, null: false, default: 0
      t.datetime :edited_at
      t.references :approved_by, foreign_key: { to_table: :chat_members, on_delete: :nullify }, index: false
      t.datetime :approved_at
      t.references :deleted_by, foreign_key: { to_table: :chat_members, on_delete: :nullify }, index: false
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :chat_messages, [:room_id, :id], order: { id: :desc }
    add_index :chat_messages, [:room_id, :id], where: "status = 'pending' AND deleted_at IS NULL", name: 'index_chat_messages_pending'
    add_index :chat_messages, :recipient_member_id, where: 'recipient_member_id IS NOT NULL'
    add_index :chat_messages, :reply_to_id, where: 'reply_to_id IS NOT NULL'
    add_index :chat_messages, :created_at

    create_table :chat_reactions do |t|
      t.references :message, null: false, foreign_key: { to_table: :chat_messages, on_delete: :cascade }, index: false
      t.references :member, null: false, foreign_key: { to_table: :chat_members, on_delete: :cascade }
      t.string :emoji, null: false

      t.datetime :created_at, null: false
    end
    add_index :chat_reactions, [:message_id, :member_id, :emoji], unique: true
  end
end
