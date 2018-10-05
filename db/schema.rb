# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2012_10_29_115333) do

  create_table "fudges", force: :cascade do |t|
    t.integer "player_id"
    t.integer "season"
    t.string "notes"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_fudges_on_player_id"
    t.index ["season"], name: "index_fudges_on_season"
  end

  create_table "locales", force: :cascade do |t|
    t.string "place"
    t.string "phone"
    t.string "other"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name"
    t.string "password_salt"
    t.string "sha512_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_scores_on_player_id"
    t.index ["season"], name: "index_scores_on_season"
    t.index ["wimps"], name: "index_scores_on_wimps"
    t.index ["win"], name: "index_scores_on_win"
  end

end
