class CreateFinancialPlans < ActiveRecord::Migration
  def change
    create_table :financial_plans do |t|
      
      t.integer    :mandante,       limit: 3
      t.integer    :societa,        limit: 4
      t.integer    :anno,           limit: 4
      t.string     :tipo_conto,     limit: 1
      t.integer    :livello,        limit: 1
      t.string     :conto,          limit: 16
      t.text       :voce
      t.decimal    :importo,        precision: 15, scale: 2
      t.decimal    :importo_01,     precision: 15, scale: 2
      t.decimal    :importo_02,     precision: 15, scale: 2
      t.decimal    :importo_03,     precision: 15, scale: 2
      t.decimal    :importo_04,     precision: 15, scale: 2
      t.decimal    :importo_05,     precision: 15, scale: 2
      t.decimal    :importo_06,     precision: 15, scale: 2
      t.decimal    :importo_07,     precision: 15, scale: 2
      t.decimal    :importo_08,     precision: 15, scale: 2
      t.decimal    :importo_09,     precision: 15, scale: 2
      t.decimal    :importo_10,     precision: 15, scale: 2
      t.decimal    :importo_11,     precision: 15, scale: 2
      t.decimal    :importo_12,     precision: 15, scale: 2
      t.decimal    :importo_q1,     precision: 15, scale: 2
      t.decimal    :importo_q2,     precision: 15, scale: 2
      t.decimal    :importo_q3,     precision: 15, scale: 2
      t.decimal    :importo_q4,     precision: 15, scale: 2
      t.text       :ricerca
      t.timestamps null: false
    end
    add_index :financial_plans, [:mandante, :societa, :anno, :conto], :unique => true
  end
end
