namespace :etl_csv do
  require 'mysql2'
  require 'csv'

  desc "carico dati estratti al 5 livello per conto e data movimento in formato csv su mysql2"
  task :import => :environment do
    puts "Accodo dati in formato csv per conto di 5 livello e data del movimento di environment #{Rails.env}"

    client = Mysql2::Client.new(:host => "localhost", :username => "root", :database => "pubblicalo_api_development")

    CSV.foreach('db/PubblicaLo2016_mensile.csv', :headers => true) do |row|
      client.query("insert into etl_mandati_reversali (mandante, societa, conto, importo, data) VALUES
      (#{row['mandante']}, #{row['societa']}, #{row['conto']}, #{row['importo']}, #{row['data']})")
    end

    client.close
  end

end
