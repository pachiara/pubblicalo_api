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

ActiveRecord::Schema.define(version: 20160215153214) do

  create_table "etl_mandati_reversali" force: :cascade do |t|
    t.integer  "mandante",   limit: 3
    t.integer  "societa",    limit: 4
    t.string   "conto",      limit: 16
    t.decimal  "importo",    precision: 15, scale: 2
    t.date     "data"
  end

  add_index "etl_mandati_reversali", ["conto", "data"], name: "etl_conto_data", using: :btree

  create_table "financial_plans", force: :cascade do |t|
    t.integer  "mandante",   limit: 3
    t.integer  "societa",    limit: 4
    t.integer  "anno",       limit: 4
    t.string   "tipo_conto", limit: 1
    t.integer  "livello",    limit: 1
    t.string   "conto",      limit: 16
    t.text     "voce",       limit: 65535
    t.decimal  "importo",                  precision: 15, scale: 2
    t.decimal  "importo_01",               precision: 15, scale: 2
    t.decimal  "importo_02",               precision: 15, scale: 2
    t.decimal  "importo_03",               precision: 15, scale: 2
    t.decimal  "importo_04",               precision: 15, scale: 2
    t.decimal  "importo_05",               precision: 15, scale: 2
    t.decimal  "importo_06",               precision: 15, scale: 2
    t.decimal  "importo_07",               precision: 15, scale: 2
    t.decimal  "importo_08",               precision: 15, scale: 2
    t.decimal  "importo_09",               precision: 15, scale: 2
    t.decimal  "importo_10",               precision: 15, scale: 2
    t.decimal  "importo_11",               precision: 15, scale: 2
    t.decimal  "importo_12",               precision: 15, scale: 2
    t.decimal  "importo_q1",               precision: 15, scale: 2
    t.decimal  "importo_q2",               precision: 15, scale: 2
    t.decimal  "importo_q3",               precision: 15, scale: 2
    t.decimal  "importo_q4",               precision: 15, scale: 2
    t.text     "ricerca",    limit: 65535
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "financial_plans", ["mandante", "societa", "anno", "conto"], name: "index_financial_plans_on_mandante_and_societa_and_anno_and_conto", unique: true, using: :btree

  create_table "piano_finanziario_2016", force: :cascade do |t|
    t.string "conto",      limit: 16
    t.string "tipo_conto", limit: 1
    t.string "livello",    limit: 3
    t.string "voce",       limit: 255
  end

  add_index "piano_finanziario_2016", ["conto"], name: "index_piano_finanziario_2016_conto", unique: true, using: :btree

end
