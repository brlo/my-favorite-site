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

ActiveRecord::Schema[8.1].define(version: 2026_11_14_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgroonga"

  create_table "bib_words", force: :cascade do |t|
    t.integer "bw_id", null: false
    t.string "word", null: false
    t.string "dict_word"
    t.integer "counts", default: 0, null: false
    t.integer "counts_by_lexema", default: 0, null: false
    t.string "lexema"
    t.jsonb "info", default: {}, null: false
    t.jsonb "transcriptions", default: {}, null: false
    t.jsonb "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "addrs", default: [], null: false, array: true
    t.index ["bw_id"], name: "index_bib_words_on_bw_id", unique: true
    t.index ["lexema"], name: "index_bib_words_on_lexema"
    t.index ["word"], name: "index_bib_words_on_word", unique: true
  end

  create_table "bible_references", force: :cascade do |t|
    t.bigint "page_id", null: false
    t.string "lang", limit: 10, null: false
    t.string "book_code", limit: 20, null: false
    t.integer "chapter", null: false
    t.integer "verse_start", null: false
    t.integer "verse_end", null: false
    t.text "context_before"
    t.integer "position_in_page", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "author_page_id"
    t.text "snippet"
    t.string "digest", limit: 32
    t.index ["author_page_id"], name: "index_bible_references_on_author_page_id"
    t.index ["book_code", "chapter", "verse_start", "verse_end"], name: "idx_bible_refs_on_book_chapter_verses"
    t.index ["digest"], name: "index_bible_references_on_digest"
    t.index ["lang", "book_code", "chapter", "verse_start", "verse_end"], name: "idx_on_lang_book_code_chapter_verse_start_verse_end_90195d0c2d"
    t.index ["lang", "book_code", "chapter"], name: "idx_bible_refs_on_lang_book_chapter"
    t.index ["page_id", "book_code", "chapter", "verse_start", "verse_end"], name: "idx_unique_bible_ref_on_page", unique: true
    t.index ["page_id"], name: "index_bible_references_on_page_id"
  end

  create_table "books", force: :cascade do |t|
    t.text "book_color"
    t.decimal "book_number"
    t.text "short_name"
    t.text "long_name"
  end

  create_table "chat_members", force: :cascade do |t|
    t.string "kind", null: false
    t.string "role", null: false
    t.bigint "user_id"
    t.string "guest_token_digest"
    t.string "nickname", null: false
    t.string "bio"
    t.string "avatar"
    t.string "title"
    t.string "ui_lang", default: "en", null: false
    t.string "landing_url"
    t.string "landing_referrer"
    t.datetime "landing_at"
    t.string "chat_entry_url"
    t.string "ip_hash"
    t.datetime "muted_until"
    t.datetime "banned_until"
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nickname)::text)", name: "index_chat_members_on_lower_nickname", unique: true
    t.index ["guest_token_digest"], name: "index_chat_members_on_guest_token_digest", unique: true
    t.index ["user_id"], name: "index_chat_members_on_user_id", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "member_id", null: false
    t.bigint "reply_to_id"
    t.bigint "recipient_member_id"
    t.string "kind", default: "text", null: false
    t.string "status", null: false
    t.string "visibility", default: "public", null: false
    t.jsonb "body_json"
    t.text "body_html"
    t.text "body_text"
    t.string "lang", null: false
    t.jsonb "translations", default: {}, null: false
    t.jsonb "reactions_summary", default: {}, null: false
    t.integer "edits_count", default: 0, null: false
    t.datetime "edited_at"
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.bigint "deleted_by_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_chat_messages_on_created_at"
    t.index ["member_id"], name: "index_chat_messages_on_member_id"
    t.index ["recipient_member_id"], name: "index_chat_messages_on_recipient_member_id", where: "(recipient_member_id IS NOT NULL)"
    t.index ["reply_to_id"], name: "index_chat_messages_on_reply_to_id", where: "(reply_to_id IS NOT NULL)"
    t.index ["room_id", "id"], name: "index_chat_messages_on_room_id_and_id", order: { id: :desc }
    t.index ["room_id", "id"], name: "index_chat_messages_pending", where: "(((status)::text = 'pending'::text) AND (deleted_at IS NULL))"
  end

  create_table "chat_reactions", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.bigint "member_id", null: false
    t.string "emoji", null: false
    t.datetime "created_at", null: false
    t.index ["member_id"], name: "index_chat_reactions_on_member_id"
    t.index ["message_id", "member_id", "emoji"], name: "index_chat_reactions_on_message_id_and_member_id_and_emoji", unique: true
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title"
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_chat_rooms_on_slug", unique: true
  end

  create_table "dict_words", force: :cascade do |t|
    t.string "dict", null: false
    t.string "word", null: false
    t.string "word_simple", null: false
    t.string "word_simple_no_endings"
    t.string "sinonim"
    t.string "lexema"
    t.string "transcription"
    t.string "transcription_lat"
    t.string "translation_short"
    t.string "translation"
    t.string "tag"
    t.text "desc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dict"], name: "index_dict_words_on_dict"
    t.index ["tag"], name: "index_dict_words_on_tag"
    t.index ["word_simple"], name: "index_dict_words_on_word_simple"
  end

  create_table "images", force: :cascade do |t|
    t.string "title"
    t.string "simple"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "h_id"
  end

  create_table "info", force: :cascade do |t|
    t.text "name"
    t.text "value"
  end

  create_table "lexemas", force: :cascade do |t|
    t.string "word", null: false
    t.string "lexema"
    t.string "lexema_clean"
    t.string "transcription"
    t.integer "counts", default: 0, null: false
    t.text "xml_doc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lexema"], name: "index_lexemas_on_lexema"
    t.index ["word", "lexema"], name: "index_lexemas_on_word_and_lexema", unique: true
    t.index ["word"], name: "index_lexemas_on_word"
  end

  create_table "menus", force: :cascade do |t|
    t.bigint "parent_id"
    t.bigint "page_id", null: false
    t.string "title", null: false
    t.string "path"
    t.boolean "is_gold", default: false
    t.boolean "is_empty", default: false
    t.integer "priority", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_menus_on_page_id"
    t.index ["parent_id"], name: "index_menus_on_parent_id"
    t.index ["path"], name: "index_menus_on_path"
  end

  create_table "page_paragraphs", force: :cascade do |t|
    t.bigint "page_id", null: false
    t.integer "position", null: false
    t.text "content", null: false
    t.tsvector "content_tsvector"
    t.string "lang", null: false
    t.index ["content"], name: "idx_page_paragraphs_content_default", where: "((lang)::text <> 'ja'::text)", using: :pgroonga
    t.index ["content"], name: "idx_page_paragraphs_content_mecab", where: "((lang)::text = 'ja'::text)", using: :pgroonga
    t.index ["content_tsvector"], name: "index_page_paragraphs_on_content_tsvector", using: :gin
    t.index ["page_id"], name: "index_page_paragraphs_on_page_id"
    t.index ["position"], name: "index_page_paragraphs_on_position"
  end

  create_table "pages", force: :cascade do |t|
    t.bigint "parent_id"
    t.bigint "user_id"
    t.integer "editors", default: [], array: true
    t.integer "page_type", default: 1, null: false
    t.boolean "is_bibleox", default: false, null: false
    t.boolean "is_menu_icons", default: false, null: false
    t.boolean "is_published", default: false, null: false
    t.boolean "is_deleted"
    t.boolean "is_search", default: true, null: false
    t.boolean "is_show_parent", default: true, null: false
    t.integer "edit_mode", default: 1, null: false
    t.string "title", null: false
    t.string "title_sub"
    t.string "meta_desc"
    t.string "path", null: false
    t.string "path_low", null: false
    t.string "redirect_from"
    t.string "audio"
    t.string "lang", null: false
    t.text "body"
    t.text "body_rendered"
    t.jsonb "verses", default: []
    t.text "references"
    t.text "references_rendered"
    t.jsonb "body_menu", default: []
    t.jsonb "links", default: []
    t.integer "priority"
    t.string "cover"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "group_lang_id", null: false
    t.string "h_id"
    t.string "period_start"
    t.integer "date_start_int"
    t.string "period_end"
    t.integer "date_end_int"
    t.boolean "is_past"
    t.string "cover_overlay_bg"
    t.string "cover_overlay_text"
    t.index ["lang", "path"], name: "index_pages_on_lang_and_path"
    t.index ["parent_id"], name: "index_pages_on_parent_id"
    t.index ["path_low"], name: "index_pages_on_path_low", unique: true
    t.index ["redirect_from"], name: "index_pages_on_redirect_from", where: "(redirect_from IS NOT NULL)"
    t.index ["title"], name: "index_pages_on_title"
    t.index ["updated_at"], name: "index_pages_on_updated_at"
    t.index ["user_id"], name: "index_pages_on_user_id"
  end

  create_table "segments", force: :cascade do |t|
    t.integer "part", null: false
    t.integer "chapter", null: false
    t.integer "paragraph", null: false
    t.integer "line"
    t.string "lang"
    t.text "text"
    t.boolean "is_original", default: false
    t.jsonb "open_tags", default: []
    t.jsonb "close_tags", default: []
    t.bigint "translation_project_id", null: false
    t.bigint "source_segment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_segment_id"], name: "index_segments_on_source_segment_id"
    t.index ["translation_project_id", "lang"], name: "index_segments_on_translation_project_id_and_lang"
    t.index ["translation_project_id", "part", "chapter", "paragraph", "line", "lang"], name: "idx_on_translation_project_id_part_chapter_paragrap_3a450d47ec"
    t.index ["translation_project_id"], name: "index_segments_on_translation_project_id"
  end

  create_table "translation_projects", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "source_langs", default: [], array: true
    t.bigint "page_ids", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "translation_reactions", force: :cascade do |t|
    t.bigint "translation_id", null: false
    t.bigint "user_id", null: false
    t.integer "reaction"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translation_id"], name: "index_translation_reactions_on_translation_id"
    t.index ["user_id", "translation_id"], name: "index_translation_reactions_on_user_id_and_translation_id", unique: true
    t.index ["user_id"], name: "index_translation_reactions_on_user_id"
  end

  create_table "translations", force: :cascade do |t|
    t.text "text", null: false
    t.text "sub_text"
    t.string "lang", null: false
    t.string "source_lang"
    t.integer "vote_score", default: 0
    t.jsonb "votes", default: {}
    t.boolean "is_approved", default: false
    t.bigint "translation_project_id", null: false
    t.bigint "segment_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_approved"], name: "index_translations_on_is_approved", where: "(is_approved = true)"
    t.index ["segment_id", "lang"], name: "index_translations_on_segment_id_and_lang"
    t.index ["segment_id"], name: "index_translations_on_segment_id"
    t.index ["translation_project_id"], name: "index_translations_on_translation_project_id"
    t.index ["user_id"], name: "index_translations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "name"
    t.string "password_digest"
    t.string "provider", null: false
    t.string "uid"
    t.string "api_token", null: false
    t.string "allow_ips", default: [], array: true
    t.boolean "is_admin", default: false
    t.jsonb "privs", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pages_owner", default: [], array: true
    t.string "email"
    t.string "salt"
    t.string "crypted_password"
    t.string "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.integer "failed_logins_count", default: 0
    t.datetime "lock_expires_at"
    t.string "unlock_token"
    t.datetime "last_activity_at"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.string "last_login_from_ip_address"
    t.string "activation_state"
    t.string "activation_token"
    t.datetime "activation_token_expires_at"
    t.boolean "is_blocked"
    t.index ["activation_token"], name: "index_users_on_activation_token"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["last_logout_at", "last_activity_at"], name: "index_users_on_last_logout_at_and_last_activity_at"
    t.index ["remember_me_token"], name: "index_users_on_remember_me_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username", "provider"], name: "index_users_on_username_and_provider"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "verses", force: :cascade do |t|
    t.string "tr_code", null: false
    t.string "lang", null: false
    t.string "address", null: false
    t.boolean "zavet", null: false
    t.integer "book_id", null: false
    t.string "book", null: false
    t.integer "chapter", null: false
    t.integer "line", null: false
    t.text "text", null: false
    t.text "text_search"
    t.jsonb "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.tsvector "text_tsvector"
    t.index ["text_search"], name: "idx_verses_text_search_default", where: "((tr_code)::text <> 'jp-ni'::text)", using: :pgroonga
    t.index ["text_search"], name: "idx_verses_text_search_mecab", where: "((tr_code)::text = 'jp-ni'::text)", using: :pgroonga
    t.index ["text_tsvector"], name: "index_verses_on_text_tsvector", using: :gin
    t.index ["tr_code", "book", "chapter"], name: "index_verses_on_tr_code_and_book_and_chapter"
    t.index ["tr_code", "book"], name: "index_verses_on_tr_code_and_book"
    t.index ["tr_code", "book_id", "chapter", "line"], name: "index_verses_on_tr_code_and_book_id_and_chapter_and_line", unique: true
    t.index ["tr_code", "zavet"], name: "index_verses_on_tr_code_and_zavet"
  end

  add_foreign_key "bible_references", "pages"
  add_foreign_key "chat_members", "users", on_delete: :nullify
  add_foreign_key "chat_messages", "chat_members", column: "approved_by_id", on_delete: :nullify
  add_foreign_key "chat_messages", "chat_members", column: "deleted_by_id", on_delete: :nullify
  add_foreign_key "chat_messages", "chat_members", column: "member_id", on_delete: :cascade
  add_foreign_key "chat_messages", "chat_members", column: "recipient_member_id", on_delete: :cascade
  add_foreign_key "chat_messages", "chat_messages", column: "reply_to_id", on_delete: :nullify
  add_foreign_key "chat_messages", "chat_rooms", column: "room_id"
  add_foreign_key "chat_reactions", "chat_members", column: "member_id", on_delete: :cascade
  add_foreign_key "chat_reactions", "chat_messages", column: "message_id", on_delete: :cascade
  add_foreign_key "page_paragraphs", "pages"
  add_foreign_key "pages", "pages", column: "parent_id"
  add_foreign_key "pages", "users"
  add_foreign_key "segments", "segments", column: "source_segment_id"
  add_foreign_key "segments", "translation_projects"
  add_foreign_key "translation_reactions", "translations"
  add_foreign_key "translation_reactions", "users"
  add_foreign_key "translations", "segments"
  add_foreign_key "translations", "translation_projects"
  add_foreign_key "translations", "users"
end
