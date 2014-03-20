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

ActiveRecord::Schema.define(version: 20140318124644) do

  create_table "applications", force: true do |t|
    t.string   "name",                         null: false
    t.string   "encrypted_secret",  limit: 64, null: false
    t.integer  "key_expire"
    t.integer  "cached_key_expire"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applications", ["name"], name: "index_applications_on_name", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.integer  "application_id",            null: false
    t.string   "secret",         limit: 16, null: false
    t.string   "user_id",                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["application_id", "user_id"], name: "index_users_on_application_id_and_user_id", unique: true, using: :btree

end
