# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121029115333) do

  create_table "fudges", :force => true do |t|
    t.integer  "player_id"
    t.integer  "season"
    t.string   "notes"
    t.integer  "warps"
    t.integer  "games"
    t.integer  "nights"
    t.integer  "wins"
    t.integer  "cfbs"
    t.integer  "come_ons"
    t.integer  "wimps"
    t.integer  "mystery_factors"
    t.integer  "gold_stars"
    t.integer  "nights_won"
    t.integer  "high_night"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fudges", ["player_id"], :name => "index_fudges_on_player_id"
  add_index "fudges", ["season"], :name => "index_fudges_on_season"

  create_table "locales", :force => true do |t|
    t.string   "place"
    t.string   "phone"
    t.string   "other"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "players", :force => true do |t|
    t.string   "name",            :null => false
    t.string   "display_name"
    t.string   "password_salt"
    t.string   "sha512_password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "players", ["name"], :name => "index_players_on_name", :unique => true

  create_table "scores", :force => true do |t|
    t.integer  "player_id",      :null => false
    t.integer  "game_id"
    t.integer  "night"
    t.integer  "season"
    t.integer  "warps"
    t.integer  "wimps"
    t.boolean  "win"
    t.boolean  "cfb"
    t.boolean  "come_on"
    t.boolean  "mystery_factor"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "scores", ["player_id"], :name => "index_scores_on_player_id"
  add_index "scores", ["season"], :name => "index_scores_on_season"
  add_index "scores", ["wimps"], :name => "index_scores_on_wimps"
  add_index "scores", ["win"], :name => "index_scores_on_win"

end
