class AddSeoKindToPages < ActiveRecord::Migration[7.1]
  # Вид поисковой разметки: 'person' - страница автора, 'book' - страница книги, NULL - обычная статья
  def change
    add_column :pages, :seo_kind, :string
    add_index :pages, :seo_kind
  end
end
