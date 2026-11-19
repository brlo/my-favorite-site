class AddLastReadMessageIdToChatMembers < ActiveRecord::Migration[8.1]
  def up
    add_column :chat_members, :last_read_message_id, :bigint, null: false, default: 0

    # Всю историю до появления счётчика считаем прочитанной,
    # иначе у действующих участников при первом заходе будет «99+».
    execute 'UPDATE chat_members SET last_read_message_id = COALESCE((SELECT MAX(id) FROM chat_messages), 0)'
  end

  def down
    remove_column :chat_members, :last_read_message_id
  end
end
