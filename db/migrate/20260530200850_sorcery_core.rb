class SorceryCore < ActiveRecord::Migration[8.1]
  def change
    change_table :users do |t|
      t.string :email
      t.string :salt
      t.string :crypted_password

      t.string :remember_me_token
      t.datetime :remember_me_token_expires_at

      t.string :reset_password_token
      t.datetime :reset_password_token_expires_at
      t.datetime :reset_password_email_sent_at

      t.integer :failed_logins_count, default: 0
      t.datetime :lock_expires_at
      t.string :unlock_token

      t.datetime :last_activity_at
      t.datetime :last_login_at
      t.datetime :last_logout_at
      t.string :last_login_from_ip_address
    end
    add_index :users, [:last_logout_at, :last_activity_at]

    add_index :users, :remember_me_token, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :unlock_token, unique: true
  end
end
