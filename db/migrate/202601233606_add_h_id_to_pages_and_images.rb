class AddHIdToPagesAndImages < ActiveRecord::Migration[8.0]
  def up
    add_column(:pages, :h_id, :string) unless column_exists?(:pages, :h_id)
    add_column(:images, :h_id, :string) unless column_exists?(:images, :h_id)
  end

  def down
    remove_column(:pages, :h_id, :string) if column_exists?(:pages, :h_id)
    remove_column(:images, :h_id, :string) if column_exists?(:images, :h_id)
  end
end
