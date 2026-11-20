class UniquePageReactionPerIp < ActiveRecord::Migration[8.1]
  # Читатель выбирает один вид реакции на статью; смена вида заменяет прежний,
  # а не добавляет вторую реакцию. Поэтому уникальность — по статье и IP.
  def change
    remove_index :page_reactions, name: 'index_page_reactions_on_page_ip_kind'
    add_index :page_reactions, %i[page_id ip_digest], unique: true,
              name: 'index_page_reactions_on_page_and_ip'
  end
end
