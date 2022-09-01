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

ActiveRecord::Schema[7.0].define(version: 0) do
  create_table "books", force: :cascade do |t|
    t.text "book_color"
    t.decimal "book_number"
    t.text "short_name"
    t.text "long_name"
  end

  create_table "info", force: :cascade do |t|
    t.text "name"
    t.text "value"
  end

  create_table "verses", force: :cascade do |t|
    t.decimal "book_number"
    t.decimal "chapter"
    t.decimal "verse"
    t.text "text"
    t.index ["book_number", "chapter", "verse"], name: "verses_index", unique: true
  end

end
