class AddIsBlockedToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :is_blocked, :boolean
  end
end
