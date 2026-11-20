class AddIsNewsToPages < ActiveRecord::Migration[8.1]
  # Флаг «новостная лента»: страница попадает в /{locale}/news.
  # Индекс частичный: в ленту смотрим только помеченные статьи.
  def change
    add_column :pages, :is_news, :boolean, default: false, null: false
    add_index :pages, %i[lang created_at], where: 'is_news = true', name: 'index_pages_on_news_feed'
  end
end
