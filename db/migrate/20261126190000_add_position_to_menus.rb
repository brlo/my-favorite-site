class AddPositionToMenus < ActiveRecord::Migration[8.1]
  def change
    # Явный порядок, который автор задал в кабинете. NULL — старый порядок
    # (сначала пункты без подпунктов, затем разделы, внутри — по priority).
    add_column :menus, :position, :integer
  end
end
