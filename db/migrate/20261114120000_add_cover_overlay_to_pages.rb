class AddCoverOverlayToPages < ActiveRecord::Migration[7.1]
  def change
    add_column :pages, :cover_overlay_bg, :string
    add_column :pages, :cover_overlay_text, :string
  end
end
