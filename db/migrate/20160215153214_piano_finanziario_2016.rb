class PianoFinanziario2016 < ActiveRecord::Migration[5.1]
  def change
    create_table "piano_finanziario_2016", force: :cascade do |t|
      t.string "conto",      limit: 16
      t.string "tipo_conto", limit: 1
      t.string "livello",    limit: 3
      t.string "voce",       limit: 255
    end
    add_index "piano_finanziario_2016", ["conto"], name: "index_piano_finanziario_2016_conto", unique: true, using: :btree
  end
end
