class CreateUsers < ActiveRecord::Migration[8.0]
  def up
    create_table :users do |t|
      t.string :username, null: false
      t.string :name
      t.string :password_digest
      t.string :provider, null: false
      t.string :uid
      t.string :api_token, null: false
      t.string :allow_ips, array: true, default: []
      t.boolean :is_admin, default: false
      t.jsonb :privs, default: {}
      t.string :pages_owner, array: true, default: []

      t.timestamps null: false
    end

    add_index :users, :api_token, unique: true
    add_index :users, :username, unique: true
    add_index :users, %i[username provider]
  end

  def down
    drop_table :users
  end
end
