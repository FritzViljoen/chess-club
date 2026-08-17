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

ActiveRecord::Schema[8.1].define(version: 2026_08_17_133105) do
  create_table "contest_results", force: :cascade do |t|
    t.integer "contest_id", null: false
    t.datetime "created_at", null: false
    t.integer "person_id", null: false
    t.integer "place", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_id", "person_id"], name: "index_contest_results_on_contest_id_and_person_id", unique: true
    t.index ["contest_id"], name: "index_contest_results_on_contest_id"
    t.index ["person_id"], name: "index_contest_results_on_person_id"
  end

  create_table "contests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "played_at", null: false
    t.datetime "updated_at", null: false
    t.index ["played_at"], name: "index_contests_on_played_at"
  end

  create_table "people", force: :cascade do |t|
    t.date "born_on", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.date "joined_on", null: false
    t.string "name", null: false
    t.string "surname", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_people_on_email", unique: true, where: "email != ''"
  end

  create_table "standings_cache", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "position", null: false
    t.index ["person_id"], name: "index_standings_cache_on_person_id", unique: true
    t.index ["position"], name: "index_standings_cache_on_position", unique: true
  end

  add_foreign_key "contest_results", "contests"
  add_foreign_key "contest_results", "people"
end
