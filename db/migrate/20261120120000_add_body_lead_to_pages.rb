class AddBodyLeadToPages < ActiveRecord::Migration[8.1]
  def change
    # Часть статьи до метки деления (аналог habracut): показывается до оглавления
    add_column :pages, :body_lead, :text
  end
end
