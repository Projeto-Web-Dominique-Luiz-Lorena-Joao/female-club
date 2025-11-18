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

ActiveRecord::Schema[8.0].define(version: 2025_11_18_084103) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.bigint "guarantor_id"
    t.index ["cpf"], name: "index_customers_on_cpf", unique: true, where: "(cpf IS NOT NULL)"
    t.index ["email"], name: "index_customers_on_email", where: "(email IS NOT NULL)"
    t.index ["full_name"], name: "index_customers_on_full_name"
    t.index ["guarantor_id"], name: "index_customers_on_guarantor_id"
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

  create_table "guarantors", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "cpf"
    t.string "phone"
    t.text "address"
    t.string "relationship"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cpf"], name: "index_guarantors_on_cpf"
    t.index ["phone"], name: "index_guarantors_on_phone"
    t.index ["relationship"], name: "index_guarantors_on_relationship"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "supplier_id"
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2
    t.boolean "active", default: true
    t.string "brand"
    t.string "color"
    t.float "quantity"
    t.decimal "purchase_price", precision: 10, scale: 2
    t.decimal "sale_price", precision: 10, scale: 2
    t.string "category"
    t.integer "min_stock"
    t.text "location"
    t.text "notes"
    t.string "unit"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "employee_id", null: false
    t.date "sale_date", null: false
    t.date "due_date"
    t.integer "discount_percentage", default: 0
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.string "payment_method", null: false
    t.text "notes"
    t.string "status", null: false
    t.date "paid_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "sale_date"], name: "index_sales_on_customer_id_and_sale_date"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["due_date"], name: "index_sales_on_due_date"
    t.index ["employee_id", "sale_date"], name: "index_sales_on_employee_id_and_sale_date"
    t.index ["employee_id"], name: "index_sales_on_employee_id"
    t.index ["paid_date"], name: "index_sales_on_paid_date"
    t.index ["payment_method"], name: "index_sales_on_payment_method"
    t.index ["sale_date"], name: "index_sales_on_sale_date"
    t.index ["status", "due_date"], name: "index_sales_on_status_and_due_date"
    t.index ["status"], name: "index_sales_on_status"
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
    t.string "status", default: "ativo"
    t.index ["legal_name"], name: "index_suppliers_on_legal_name"
    t.index ["product_category"], name: "index_suppliers_on_product_category"
    t.index ["status"], name: "index_suppliers_on_status"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "customers", "guarantors"
  add_foreign_key "products", "suppliers"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "employees"
end
