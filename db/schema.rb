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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151112074312) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "notifications", force: :cascade do |t|
    t.integer  "pull_request_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "notified_users", force: :cascade do |t|
    t.integer "notification_id"
    t.integer "user_id"
  end

  add_index "notified_users", ["notification_id"], name: "index_notified_users_on_notification_id", using: :btree
  add_index "notified_users", ["user_id"], name: "index_notified_users_on_user_id", using: :btree

  create_table "pull_requests", force: :cascade do |t|
    t.integer  "number",        null: false
    t.string   "html_url"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "repository_id", null: false
    t.string   "body"
    t.string   "title"
  end

  create_table "repositories", force: :cascade do |t|
    t.string   "name",           null: false
    t.string   "webhook_secret", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "access_via_id",  null: false
  end

  add_index "repositories", ["name"], name: "index_repositories_on_name", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.string   "github_username"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["github_username"], name: "index_users_on_github_username", unique: true, using: :btree
  add_index "users", ["provider"], name: "index_users_on_provider", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", using: :btree

  add_foreign_key "notifications", "pull_requests"
  add_foreign_key "pull_requests", "repositories"
  add_foreign_key "repositories", "users", column: "access_via_id"
end
