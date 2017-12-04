class AddIndexToPopulation < ActiveRecord::Migration[5.1]
  def up
    add_index :populations, [:code, :year], name: 'index_population_code_year', :unique => true
  end
  def down
    remove_index :populations, [:code, :year]
  end
end
