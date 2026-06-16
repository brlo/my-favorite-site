# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_06_120721) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgroonga"

  create_table "bib_words", force: :cascade do |t|
    t.string "addrs", default: [], null: false, array: true
    t.integer "bw_id", null: false
    t.integer "counts", default: 0, null: false
    t.integer "counts_by_lexema", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "dict_word"
    t.jsonb "info", default: {}, null: false
    t.string "lexema"
    t.jsonb "transcriptions", default: {}, null: false
    t.jsonb "translations", default: {}, null: false
    t.datetime "updated_at", null: false
    t.string "word", null: false
    t.index ["bw_id"], name: "index_bib_words_on_bw_id", unique: true
    t.index ["lexema"], name: "index_bib_words_on_lexema"
    t.index ["word"], name: "index_bib_words_on_word", unique: true
  end

  create_table "bible_references", force: :cascade do |t|
    t.string "book_code", limit: 20, null: false
    t.integer "chapter", null: false
    t.text "context_before"
    t.datetime "created_at", null: false
    t.string "lang", limit: 10, null: false
    t.bigint "page_id", null: false
    t.integer "position_in_page", null: false
    t.datetime "updated_at", null: false
    t.integer "verse_end", null: false
    t.integer "verse_start", null: false
    t.index ["lang", "book_code", "chapter", "verse_start", "verse_end"], name: "idx_on_lang_book_code_chapter_verse_start_verse_end_90195d0c2d"
    t.index ["page_id"], name: "index_bible_references_on_page_id"
  end

  create_table "books", force: :cascade do |t|
    t.text "book_color"
    t.decimal "book_number"
    t.text "long_name"
    t.text "short_name"
  end

  create_table "dict_words", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "desc"
    t.string "dict", null: false
    t.string "lexema"
    t.string "sinonim"
    t.string "tag"
    t.string "transcription"
    t.string "transcription_lat"
    t.string "translation"
    t.string "translation_short"
    t.datetime "updated_at", null: false
    t.string "word", null: false
    t.string "word_simple", null: false
    t.string "word_simple_no_endings"
    t.index ["dict"], name: "index_dict_words_on_dict"
    t.index ["tag"], name: "index_dict_words_on_tag"
    t.index ["word_simple"], name: "index_dict_words_on_word_simple"
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "h_id"
    t.string "simple"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
  end

  create_table "info", force: :cascade do |t|
    t.text "name"
    t.text "value"
  end

  create_table "lexemas", force: :cascade do |t|
    t.integer "counts", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "lexema"
    t.string "lexema_clean"
    t.string "transcription"
    t.datetime "updated_at", null: false
    t.string "word", null: false
    t.text "xml_doc"
    t.index ["lexema"], name: "index_lexemas_on_lexema"
    t.index ["word", "lexema"], name: "index_lexemas_on_word_and_lexema", unique: true
    t.index ["word"], name: "index_lexemas_on_word"
  end

  create_table "menus", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_empty", default: false
    t.boolean "is_gold", default: false
    t.bigint "page_id", null: false
    t.bigint "parent_id"
    t.string "path"
    t.integer "priority", default: 0
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_menus_on_page_id"
    t.index ["parent_id"], name: "index_menus_on_parent_id"
    t.index ["path"], name: "index_menus_on_path"
  end

  create_table "page_paragraphs", force: :cascade do |t|
    t.text "content", null: false
    t.tsvector "content_tsvector"
    t.string "lang", null: false
    t.bigint "page_id", null: false
    t.integer "position", null: false
    t.index ["content"], name: "idx_page_paragraphs_content_default", where: "((lang)::text <> 'ja'::text)", using: :pgroonga
    t.index ["content"], name: "idx_page_paragraphs_content_mecab", where: "((lang)::text = 'ja'::text)", using: :pgroonga
    t.index ["page_id"], name: "index_page_paragraphs_on_page_id"
    t.index ["position"], name: "index_page_paragraphs_on_position"
  end

  create_table "pages", force: :cascade do |t|
    t.string "audio"
    t.text "body"
    t.jsonb "body_menu", default: []
    t.text "body_rendered"
    t.string "cover"
    t.datetime "created_at", null: false
    t.integer "edit_mode", default: 1, null: false
    t.integer "editors", default: [], array: true
    t.string "group_lang_id", null: false
    t.string "h_id"
    t.boolean "is_bibleox", default: false, null: false
    t.boolean "is_deleted"
    t.boolean "is_menu_icons", default: false, null: false
    t.boolean "is_past"
    t.boolean "is_published", default: false, null: false
    t.boolean "is_search", default: true, null: false
    t.boolean "is_show_parent", default: true, null: false
    t.string "lang", null: false
    t.jsonb "links", default: []
    t.string "meta_desc"
    t.integer "page_type", default: 1, null: false
    t.bigint "parent_id"
    t.string "path", null: false
    t.string "path_low", null: false
    t.integer "priority"
    t.string "redirect_from"
    t.text "references"
    t.text "references_rendered"
    t.string "title", null: false
    t.string "title_sub"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.jsonb "verses", default: []
    t.datetime "year_end"
    t.datetime "year_start"
    t.index ["lang", "path"], name: "index_pages_on_lang_and_path"
    t.index ["parent_id"], name: "index_pages_on_parent_id"
    t.index ["path_low"], name: "index_pages_on_path_low", unique: true
    t.index ["redirect_from"], name: "index_pages_on_redirect_from", where: "(redirect_from IS NOT NULL)"
    t.index ["title"], name: "index_pages_on_title"
    t.index ["updated_at"], name: "index_pages_on_updated_at"
    t.index ["user_id"], name: "index_pages_on_user_id"
  end

  create_table "segments", force: :cascade do |t|
    t.integer "chapter", null: false
    t.jsonb "close_tags", default: []
    t.datetime "created_at", null: false
    t.boolean "is_original", default: false
    t.string "lang"
    t.integer "line"
    t.jsonb "open_tags", default: []
    t.integer "paragraph", null: false
    t.bigint "source_segment_id"
    t.text "text"
    t.bigint "translation_project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["source_segment_id"], name: "index_segments_on_source_segment_id"
    t.index ["translation_project_id", "chapter", "paragraph", "line"], name: "idx_on_translation_project_id_chapter_paragraph_lin_90bd6f22b9"
    t.index ["translation_project_id", "lang"], name: "index_segments_on_translation_project_id_and_lang"
    t.index ["translation_project_id"], name: "index_segments_on_translation_project_id"
  end

  create_table "translation_projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "page_ids", default: [], array: true
    t.string "source_langs", default: [], array: true
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "translations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_approved", default: false
    t.string "lang", null: false
    t.bigint "segment_id", null: false
    t.string "source_lang"
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "vote_score", default: 0
    t.jsonb "votes", default: {}
    t.index ["is_approved"], name: "index_translations_on_is_approved", where: "(is_approved = true)"
    t.index ["segment_id", "lang"], name: "index_translations_on_segment_id_and_lang"
    t.index ["segment_id"], name: "index_translations_on_segment_id"
    t.index ["user_id"], name: "index_translations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "activation_state"
    t.string "activation_token"
    t.datetime "activation_token_expires_at"
    t.string "allow_ips", default: [], array: true
    t.string "api_token", null: false
    t.datetime "created_at", null: false
    t.string "crypted_password"
    t.string "email"
    t.integer "failed_logins_count", default: 0
    t.boolean "is_admin", default: false
    t.datetime "last_activity_at"
    t.datetime "last_login_at"
    t.string "last_login_ip"
    t.datetime "lock_expires_at"
    t.string "name"
    t.bigint "pages_owner", default: [], array: true
    t.string "password_digest"
    t.jsonb "privs", default: {}
    t.string "provider", null: false
    t.string "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.string "salt"
    t.string "uid"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["activation_token"], name: "index_users_on_activation_token"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["remember_me_token"], name: "index_users_on_remember_me_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username", "provider"], name: "index_users_on_username_and_provider"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "verses", force: :cascade do |t|
    t.string "address", null: false
    t.string "book", null: false
    t.integer "book_id", null: false
    t.integer "chapter", null: false
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}
    t.string "lang", null: false
    t.integer "line", null: false
    t.text "text", null: false
    t.text "text_search"
    t.tsvector "text_tsvector"
    t.string "tr_code", null: false
    t.datetime "updated_at", null: false
    t.boolean "zavet", null: false
    t.index ["book_id"], name: "index_verses_on_book_id"
    t.index ["text_search"], name: "idx_verses_text_search_default", where: "((tr_code)::text <> 'jp-ni'::text)", using: :pgroonga
    t.index ["text_search"], name: "idx_verses_text_search_mecab", where: "((tr_code)::text = 'jp-ni'::text)", using: :pgroonga
    t.index ["text_tsvector"], name: "index_verses_on_text_tsvector", using: :gin
    t.index ["tr_code", "book", "chapter"], name: "index_verses_on_tr_code_and_book_and_chapter"
    t.index ["tr_code", "book"], name: "index_verses_on_tr_code_and_book"
    t.index ["tr_code", "book_id", "chapter", "line"], name: "index_verses_on_tr_code_and_book_id_and_chapter_and_line", unique: true
    t.index ["tr_code", "zavet"], name: "index_verses_on_tr_code_and_zavet"
  end

  add_foreign_key "bible_references", "pages"
  add_foreign_key "page_paragraphs", "pages"
  add_foreign_key "pages", "pages", column: "parent_id"
  add_foreign_key "pages", "users"
  add_foreign_key "segments", "segments", column: "source_segment_id"
  add_foreign_key "segments", "translation_projects"
  add_foreign_key "translations", "segments"
  add_foreign_key "translations", "users"
end
