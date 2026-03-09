class ChangeUsersPagesOwnerToInt < ActiveRecord::Migration[8.0]
  def change
    # Выполнил в dev и prod вручную.
    # ActiveRecord::Migration.add_column(:users, :pages_owner_int, :bigint, array: true, default: [])
    # ::User.find_each do |u|
    #   u.update!(pages_owner_int: u.pages_owner.map(&:to_i))
    # end
    # ActiveRecord::Migration.remove_column(:users, :pages_owner)
    # ActiveRecord::Migration.rename_column(:users, :pages_owner_int, :pages_owner)
  end
end
