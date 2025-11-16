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

ActiveRecord::Schema[8.0].define(version: 2025_11_16_183147) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "full_name"
    t.string "cpf"
    t.date "birth_date"
    t.string "phone_number"
    t.string "email"
    t.text "full_address"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cpf"], name: "index_customers_on_cpf", unique: true, where: "(cpf IS NOT NULL)"
    t.index ["email"], name: "index_customers_on_email", where: "(email IS NOT NULL)"
    t.index ["full_name"], name: "index_customers_on_full_name"
    t.index ["phone_number"], name: "index_customers_on_phone_number"
  end

  create_table "employees", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "cpf", null: false
    t.string "position"
    t.string "phone"
    t.string "email"
    t.text "address"
    t.date "admission_date"
    t.decimal "salary", precision: 10, scale: 2
    t.string "work_days"
    t.text "notes"
    t.string "status", default: "ativo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cpf"], name: "index_employees_on_cpf", unique: true
    t.index ["full_name"], name: "index_employees_on_full_name"
    t.index ["position"], name: "index_employees_on_position"
    t.index ["status"], name: "index_employees_on_status"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "legal_name", null: false
    t.string "trade_name"
    t.string "phone_number"
    t.string "email"
    t.text "full_address"
    t.string "product_category"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["legal_name"], name: "index_suppliers_on_legal_name"
    t.index ["product_category"], name: "index_suppliers_on_product_category"
    t.index ["trade_name"], name: "index_suppliers_on_trade_name"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "phone"
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
end
