class CreatePages < ActiveRecord::Migration[8.0]
  def up
    create_table :pages do |t|
      # Основные атрибуты
      t.references :parent, null: true, foreign_key: { to_table: :pages }
      # автор
      t.references :user, null: true, foreign_key: true
      # ids редакторов
      t.integer :editors, array: true, default: []

      # Тип страницы (для писания и тд)
      t.integer :page_type, null: false, default: 1
      # текст-перевод подготовлен нами?
      t.boolean :is_bibleox, null: false, default: false
      # показывать ли мини-иконки рядом с пунктами меню
      t.boolean :is_menu_icons, null: false, default: false
      t.boolean :is_published, null: false, default: false
      t.boolean :is_deleted
      t.boolean :is_search, null: false, default: true
      t.boolean :is_show_parent, null: false, default: true
      t.integer :edit_mode, null: false, default: 1


      # основной заголовок
      t.string :title, null: false
      # Название части книги (Том 1, или просто "1") или годы жизни автора
      t.string :title_sub
      # meta-описание (через запятую ключевые слова)
      t.string :meta_desc

      # Пути и маршрутизация
      t.string :path, null: false
      t.string :path_low, null: false
      # старый путь к статье, с которого надо редиректить на текущий path
      t.string :redirect_from

      # аудио-файл
      t.string :audio
      # язык
      t.string :lang, null: false
      # языковой идентификатор страницы для поиска таких же страниц на другом языке
      t.string :group_lang_id, null: false

      # текст статьи (для редактирования)
      t.text :body
      # текст статьи (для показа пользователю)
      t.text :body_rendered
      t.text :body_search
      # текст статьи с разбивкой на стихи
      t.jsonb :verses, default: []
      # ссылки и заметки (для показа пользователю)
      t.text :references
      t.text :references_rendered
      # меню, построенное из распарсенных заголовков body (h2, h3, h4)
      t.jsonb :body_menu, default: []
      # ссылки на соседние страницы
      t.jsonb :links, default: []

      # приоритет
      t.integer :priority

      # Для CarrierWave (или Active Storage — здесь просто строка)
      t.string :cover

      t.timestamps null: false
    end

    # Индексы
    add_index :pages, :title
    add_index :pages, :path_low, unique: true
    add_index :pages, :group_lang_id
    # add_index :pages, :user_id
    add_index :pages, :redirect_from, where: "(redirect_from IS NOT NULL)"
    add_index :pages, :updated_at
    add_index :pages, [:lang, :path]
    # add_index :pages, :parent_id

    # Индекс для полнотекстового поиска (будет обновляться триггером или вручную)
    # https://github.com/Casecommons/pg_search
    add_column :pages, :body_tsvector, :tsvector
    add_index :pages, :body_tsvector, using: :gin

    # для теста (поиск должен работать по полю прямиком)
    # enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    # add_index :pages, :body_search, using: :gin, opclass: :gin_trgm_ops
  end

  def down
    drop_table :pages
  end
end
