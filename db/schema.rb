# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2012_10_29_115333) do

  create_table "fudges", force: :cascade do |t|
    t.integer "player_id"
    t.integer "season"
    t.string "notes", limit: 255
    t.integer "warps"
    t.integer "games"
    t.integer "nights"
    t.integer "wins"
    t.integer "cfbs"
    t.integer "come_ons"
    t.integer "wimps"
    t.integer "mystery_factors"
    t.integer "gold_stars"
    t.integer "nights_won"
    t.integer "high_night"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["player_id"], name: "index_fudges_on_player_id"
    t.index ["season"], name: "index_fudges_on_season"
  end

  create_table "locales", force: :cascade do |t|
    t.string "place", limit: 255
    t.string "phone", limit: 255
    t.string "other", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "players", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "display_name", limit: 255
    t.string "password_salt", limit: 255
    t.string "sha512_password", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_players_on_name", unique: true
  end

  create_table "scores", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "game_id"
    t.integer "night"
    t.integer "season"
    t.integer "warps"
    t.integer "wimps"
    t.boolean "win"
    t.boolean "cfb"
    t.boolean "come_on"
    t.boolean "mystery_factor"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["player_id"], name: "index_scores_on_player_id"
    t.index ["season"], name: "index_scores_on_season"
    t.index ["wimps"], name: "index_scores_on_wimps"
    t.index ["win"], name: "index_scores_on_win"
  end

end
