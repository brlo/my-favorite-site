class CreatePageParagraphs < ActiveRecord::Migration[8.0]
  def up
    create_table :page_paragraphs do |t|
      t.references :page, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :content, null: false
      t.tsvector :content_tsvector, using: :gin
      t.string :lang, null: false
      t.index :position
    end
    ActiveRecord::Migration.add_index :page_paragraphs, :content_tsvector, using: :gin
    # ActiveRecord::Base.connection.columns('page_paragraphs')
    # ActiveRecord::Base.connection.indexes('page_paragraphs')
  end

  def down
    drop_table :page_paragraphs
  end
end
