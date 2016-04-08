class EtlMandantiReversali < ActiveRecord::Migration
  def change
    create_table "etl_mandati_reversali" force: :cascade do |t|
      t.integer  "mandante",   limit: 3
      t.integer  "societa",    limit: 4
      t.string   "conto",      limit: 16
      t.decimal  "importo",    precision: 15, scale: 2
      t.date     "data"
    end
    add_index "etl_mandati_reversali", ["conto", "data"], name: "etl_conto_data", using: :btree
  end
end
