class IndexVersesPgroongaNotNullPredicates < ActiveRecord::Migration[7.1]
  # PGroonga сообщает планировщику нулевую стоимость битмапа, поэтому любой запрос
  # к verses (в том числе поиск стихов по address при рендере цитат статьи) лепит
  # к себе через AND полный битмап всех строк индекса (~100мс на запрос). Под
  # нагрузкой сотни таких запросов парализуют базу (инцидент 2026-11-18).
  #
  # Лечение: предикат `text_search IS NOT NULL` в индексе. Запросы по address
  # ничего не знают о text_search, значит предикат им «не под силу» (implication
  # check) и pgroonga перестаёт быть кандидатом. Поисковым запросам фильтр
  # безразличен: NULL-строки всё равно не матчатся, а VerseSearchPgroonga
  # добавляет то же условие в base_relation (см. verse_search_pgroonga.rb).
  disable_ddl_transaction!

  INDEXES = {
    'idx_verses_text_search_default' => [
      'text_search',
      "WITH (tokenizer='TokenNgram(\"report_source_location\", true)', normalizer='NormalizerNFKC')",
      "text_search IS NOT NULL AND (tr_code)::text <> 'jp-ni'::text",
    ],
    'idx_verses_text_search_mecab' => [
      'text_search',
      "WITH (tokenizer='TokenMecab(\"report_source_location\", true, \"use_reading\", true, \"include_reading\", true)', normalizer='NormalizerNFKC(\"unify_kana\", true)')",
      "text_search IS NOT NULL AND (tr_code)::text = 'jp-ni'::text",
    ],
    'idx_verses_text_search_arabic' => [
      'text_search_ar',
      '',
      "text_search_ar IS NOT NULL AND (lang)::text = 'ar'::text",
    ],
  }.freeze

  def up
    # собственно индекс для поиска по address: его никогда не было, все
    # `WHERE address IN (...)` жили на битмапах чужих индексов (см. выше)
    execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS index_verses_on_address ON verses (address)"
    INDEXES.keys.each { |name| execute "DROP INDEX CONCURRENTLY IF EXISTS #{name}" }
    INDEXES.each do |name, (column, options, predicate)|
      execute "CREATE INDEX CONCURRENTLY #{name} ON verses USING pgroonga (#{column}) #{options} WHERE #{predicate}"
    end
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_verses_on_address"
    INDEXES.each do |name, (column, options, _predicate)|
      old_predicate = name.include?('arabic') ? "(lang)::text = 'ar'::text" : "(tr_code)::text #{name.include?('mecab') ? '=' : '<>'} 'jp-ni'::text"
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{name}"
      execute "CREATE INDEX CONCURRENTLY #{name} ON verses USING pgroonga (#{column}) #{options} WHERE #{old_predicate}"
    end
  end
end
