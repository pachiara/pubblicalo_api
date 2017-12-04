class CreatePopulations < ActiveRecord::Migration[5.1]
  def change
    create_table :populations do |t|
      t.string     :code,    limit: 2
      t.string     :region,  limit: 50
      t.integer    :year,    limit: 4
      t.decimal    :people,  precision: 15, scale: 0

      t.timestamps
    end
  end
end
