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

ActiveRecord::Schema[7.2].define(version: 2024_11_19_055648) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "manuals", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "draft"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "revision_comments", force: :cascade do |t|
    t.bigint "section_revision_id", null: false
    t.bigint "user_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_revision_id"], name: "index_revision_comments_on_section_revision_id"
    t.index ["user_id"], name: "index_revision_comments_on_user_id"
  end

  create_table "section_revisions", force: :cascade do |t|
    t.bigint "section_id", null: false
    t.bigint "manual_id", null: false
    t.text "content"
    t.text "base_content"
    t.integer "base_version"
    t.string "status", default: "pending"
    t.string "change_type"
    t.float "position"
    t.float "base_position"
    t.text "change_description"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_section_revisions_on_created_by_id"
    t.index ["manual_id"], name: "index_section_revisions_on_manual_id"
    t.index ["section_id", "status"], name: "index_section_revisions_on_section_id_and_status"
    t.index ["section_id"], name: "index_section_revisions_on_section_id"
  end

  create_table "sections", force: :cascade do |t|
    t.bigint "manual_id", null: false
    t.text "content", null: false
    t.float "position", null: false
    t.vector "embedding", limit: 1536
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", default: 1
    t.bigint "latest_revision_id"
    t.index ["embedding"], name: "index_sections_on_embedding", using: :ivfflat
    t.index ["latest_revision_id"], name: "index_sections_on_latest_revision_id"
    t.index ["manual_id"], name: "index_sections_on_manual_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "revision_comments", "section_revisions"
  add_foreign_key "revision_comments", "users"
  add_foreign_key "section_revisions", "manuals"
  add_foreign_key "section_revisions", "sections"
  add_foreign_key "section_revisions", "users", column: "created_by_id"
  add_foreign_key "sections", "manuals"
end
