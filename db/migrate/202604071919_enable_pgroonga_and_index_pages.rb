class EnablePgroongaAndIndexPages < ActiveRecord::Migration[8.0]
  def change
    # CREATE EXTENSION IF NOT EXISTS pgroonga;
    ActiveRecord::Migration.enable_extension 'pgroonga' unless ActiveRecord::Migration.extension_enabled?('pgroonga')

    # CREATE INDEX pgroonga_content_index ON memos USING pgroonga (content);
    # ::ActiveRecord::Migration.add_index :pages, :body_search, using: :pgroonga, name: 'index_pages_on_body_search_pgroonga'
    # ::ActiveRecord::Migration.add_index :verses, :text_search, using: :pgroonga, name: 'index_verses_on_body_search_pgroonga'


    # ActiveRecord::Migration.remove_index :pages, :body_search, name: 'pages_body_search_idx'

    # ActiveRecord::Migration.remove_index :verses, :text_search, using: :pgroonga, name: 'index_verses_on_body_search_pgroonga'

    # ActiveRecord::Migration.execute <<-SQL
    #   CREATE INDEX
    #   ON pages
    #   USING pgroonga (body_search)
    #   WITH (plugins='token_filters/stem',
    #   token_filters='TokenFilterStem');
    # SQL


    # Verse.select("pgroonga_query_extract_keywords('こに純白の亜麻布', 'idx_verses_text_search_mecab') AS query_extract_keywords").first.query_extract_keywords

    # ActiveRecord::Migration.execute("SELECT indexdef FROM pg_indexes WHERE indexname = 'pages_body_search_idx';").to_a
    # ActiveRecord::Migration.execute("SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'verses';").to_a
  end
end

# add_index :pages,
#           :content,  # или другое поле, которое нужно индексировать
#           name: 'index_pages_content_on_jp_ch_pgroonga',
#           using: 'pgroonga',
#           where: "lang IN ('jp', 'ch')"

# execute <<-SQL
#   CREATE INDEX CONCURRENTLY pages_body_search_idx
#   ON pages USING pgroonga (
#     body_search pgroonga_text_full_text_search_ops_v2
#   )
#   WITH (
#     tokenizer = 'TokenNgram("unify_alphabet", false, "unify_symbol", false, "unify_digit", false)',
#     normalizers = 'NormalizerAuto'
#   )
# SQL

# ActiveRecord::Migration.remove_column :pages, :body_tsvector
# ActiveRecord::Migration.remove_column :pages, :body_search
# ActiveRecord::Base.connection.execute("VACUUM FULL pages")



# ИНДЕКСЫ ДЛЯ СТИХОВ ИЗ БИБЛИИ

# СПИСОК ИНДЕКСОВ
# ActiveRecord::Migration.execute("SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'verses' AND indexname LIKE '%text_search%';").to_a

# Зачем это?
# "report_source_location", true
# пытался настроить подсветку разного регистра, как сказно здесь https://pgroonga.github.io/reference/functions/pgroonga-highlight-html.html
# Объяснение: If you specify index_name, the specified PGroonga index must have TokenNgram tokenizer with "report_source_location" option.

# ================ DEFAULT FOR ALL ================
# ActiveRecord::Migration.execute <<-SQL
#   CREATE INDEX idx_verses_text_search_default ON verses
#   USING pgroonga (text_search)
#   WITH (tokenizer='TokenNgram("report_source_location", true)', normalizer='NormalizerNFKC')
#   WHERE tr_code != 'jp-ni';
# SQL
# # drop
# ActiveRecord::Migration.remove_index :verses, :text_search, using: :pgroonga, name: 'idx_verses_text_search_default'
# # test
# Verse.where(tr_code: 'ru').where("text_search &@~ ?", "Прости").explain

# ================ MECAB FOR JP ================
# doc: https://groonga.org/docs/reference/tokenizers/token_mecab.html
# use_reading + include_reading - позволило искать иероглифы по их чтению
#
# ActiveRecord::Migration.execute <<-SQL
#   CREATE INDEX idx_verses_text_search_mecab ON verses
#   USING pgroonga (text_search)
#   WITH (
#     tokenizer='TokenMecab("report_source_location", true, "use_reading", true, "include_reading", true)',
#     normalizer='NormalizerNFKC("unify_kana", true)')
#   WHERE tr_code = 'jp-ni';
# SQL
# # drop
# ActiveRecord::Migration.remove_index :verses, :text_search, using: :pgroonga, name: 'idx_verses_text_search_mecab'
# # test
# Verse.where(tr_code: 'jp-ni').where("text_search &@~ ?", "愛 言葉").explain



# ИНДЕКСЫ ДЛЯ ПАРАГРАФОВ

# ================ DEFAULT FOR ALL ================
# ActiveRecord::Migration.execute <<-SQL
#   CREATE INDEX idx_page_paragraphs_content_default ON page_paragraphs
#   USING pgroonga (content)
#   WITH (tokenizer='TokenNgram("report_source_location", true)', normalizer='NormalizerNFKC')
#   WHERE lang != 'ja';
# SQL
# # drop
# ActiveRecord::Migration.remove_index :page_paragraphs, :content, using: :pgroonga, name: 'idx_page_paragraphs_content_default'
# # test
# PageParagraph.where("content &@~ ?", "Прости").explain

# ================ MECAB FOR JP ================
# doc: https://groonga.org/docs/reference/tokenizers/token_mecab.html
# use_reading + include_reading - позволило искать иероглифы по их чтению
#
# ActiveRecord::Migration.execute <<-SQL
#   CREATE INDEX idx_page_paragraphs_content_mecab ON page_paragraphs
#   USING pgroonga (content)
#   WITH (
#     tokenizer='TokenMecab("report_source_location", true, "use_reading", true, "include_reading", true)',
#     normalizer='NormalizerNFKC("unify_kana", true)')
#   WHERE lang = 'ja';
# SQL
# # drop
# ActiveRecord::Migration.remove_index :page_paragraphs, :content, using: :pgroonga, name: 'idx_page_paragraphs_content_mecab'
# # test
# PageParagraph.where(lang).where("content &@~ ?", "愛 言葉").explain
