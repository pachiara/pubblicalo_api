namespace :etl do
  require 'mysql2'
  require 'csv'
  require 'date'
  require 'fileutils'

  class << self
    def root
      File.expand_path("../../../", __FILE__)
    end
    def tratta_livello(livello)
      case livello
        when "I"   then 1
        when "II"  then 2
        when "III" then 3
        when "IV"  then 4
        when "V"   then 5
      end
    end
    def database
      ActiveRecord::Base.connection_config[:database]
    end
    def username
      ActiveRecord::Base.connection_config[:username]
    end
    def password
      ActiveRecord::Base.connection_config[:password]
    end
    def host
      ActiveRecord::Base.connection_config[:host]
    end
    def url_get
      'http://localhost/etl/'
    end
    def system!(*args)
      system(*args) || abort("\n== Command #{args} failed ==")
    end
  end

  task :debug => :environment do
    Rails.env="production"
    puts "database: #{database}"
    puts "usename:  #{username}"
    puts "password: #{password}"
    puts "host:     #{host}"
    puts "environment: #{Rails.env}"
    puts "root:     #{root}"
  end

  desc "1) accodo nello stage i dati estratti al 5 livello per conto e data movimento in formato csv su mysql2"
  task :csv_import, [:giorno] => :environment do |t, args|
    puts "Task csv_import: Accodo dati in formato csv per conto di 5 livello e data del movimento di environment #{Rails.env}"

    client = Mysql2::Client.new(:host => "#{host}", :username => "#{username}", :password => "#{password}", :database => "#{database}")
    societa = 130
    data = DateTime.strptime("#{args[:giorno]}", '%d/%m/%Y').strftime('%Y.%m.%d')

    puts "Elaboro il file: #{root}/../etl/reversali_mandati_#{societa}_#{data}.csv"

    CSV.foreach("#{root}/../etl/reversali_mandati_#{societa}_#{data}.csv", :headers => true) do |row|
      client.query("insert into etl_mandati_reversali (mandante, societa, conto, importo, data) VALUES
      (#{row['mandante']}, #{row['societa']}, '#{row['conto']}', #{row['importo']}, '#{row['data']}')")
    end

    client.close
  end

  desc "2) carico dati estratti al 5 livello per conto e data movimento"
  task :dati => :environment do
    puts "Task dati: Carico dati per conto di 5 livello e data del movimento totalizzati per mese di environment #{Rails.env}"

    client = Mysql2::Client.new(:host => "#{host}", :username => "#{username}", :password => "#{password}", :database => "#{database}")

    # svuota il database
    FinancialPlan.destroy_all

    # livello di rottura per mandante, societa, anno, conto
    livello_rottura = ""

    client.query("select etl_mandati_reversali.mandante, etl_mandati_reversali.societa, year(etl_mandati_reversali.data) as anno, etl_mandati_reversali.conto, piano_finanziario_2016.voce,
    piano_finanziario_2016.tipo_conto, piano_finanziario_2016.livello, month(etl_mandati_reversali.data) as mese, sum(etl_mandati_reversali.importo) as totale_mese
    from etl_mandati_reversali JOIN piano_finanziario_2016 on etl_mandati_reversali.conto = piano_finanziario_2016.conto
    group by etl_mandati_reversali.mandante, etl_mandati_reversali.societa, anno, etl_mandati_reversali.conto, mese").each do |row|

    nuovo_livello = row["mandante"].to_s+row["societa"].to_s+row["anno"].to_s+row["conto"]

      if livello_rottura != nuovo_livello
        #puts "    creo conto: #{nuovo_livello} mese: #{row["mese"]} importo_mese: #{row["totale_mese"]}"

        FinancialPlan.create(mandante: row["mandante"], societa: row["societa"], anno: row["anno"], conto: row["conto"], importo: row["totale_mese"], tipo_conto: row["tipo_conto"],
        livello: tratta_livello(row["livello"]), voce: row["voce"], ricerca: row["voce"].downcase,
        importo_01: row["mese"]==1?row["totale_mese"]:0,  importo_02: row["mese"]==2?row["totale_mese"]:0,  importo_03: row["mese"]==3?row["totale_mese"]:0,
        importo_04: row["mese"]==4?row["totale_mese"]:0,  importo_05: row["mese"]==5?row["totale_mese"]:0,  importo_06: row["mese"]==6?row["totale_mese"]:0,
        importo_07: row["mese"]==7?row["totale_mese"]:0,  importo_08: row["mese"]==8?row["totale_mese"]:0,  importo_09: row["mese"]==9?row["totale_mese"]:0,
        importo_10: row["mese"]==10?row["totale_mese"]:0, importo_11: row["mese"]==11?row["totale_mese"]:0, importo_12: row["mese"]==12?row["totale_mese"]:0,
        importo_q1: row["mese"].between?(1, 3)? row["totale_mese"]:0, importo_q2: row["mese"].between?(4, 6)? row["totale_mese"]:0,
        importo_q3: row["mese"].between?(7, 9)? row["totale_mese"]:0, importo_q4: row["mese"].between?(10, 12)? row["totale_mese"]:0)
        livello_rottura = nuovo_livello
      else
        #puts "aggiorno conto: #{nuovo_livello} mese: #{row["mese"]} importo_mese: #{row["totale_mese"]}"

        conto = FinancialPlan.find_by(mandante: row["mandante"], societa: row["societa"], anno: row["anno"], conto: row["conto"])
        conto.update(importo: conto.importo+row["totale_mese"],
        importo_01: row["mese"]==1?row["totale_mese"]:  conto.importo_01, importo_02: row["mese"]==2?row["totale_mese"]: conto.importo_02,  importo_03: row["mese"]==3?row["totale_mese"]: conto.importo_03,
        importo_04: row["mese"]==4?row["totale_mese"]:  conto.importo_04, importo_05: row["mese"]==5?row["totale_mese"]: conto.importo_05,  importo_06: row["mese"]==6?row["totale_mese"]: conto.importo_06,
        importo_07: row["mese"]==7?row["totale_mese"]:  conto.importo_07, importo_08: row["mese"]==8?row["totale_mese"]: conto.importo_08,  importo_09: row["mese"]==9?row["totale_mese"]: conto.importo_09,
        importo_10: row["mese"]==10?row["totale_mese"]: conto.importo_10, importo_11: row["mese"]==11?row["totale_mese"]: conto.importo_11, importo_12: row["mese"]==12?row["totale_mese"]: conto.importo_12,
        importo_q1: row["mese"].between?(1, 3)? conto.importo_q1+row["totale_mese"]: conto.importo_q1, importo_q2: row["mese"].between?(4, 6)? conto.importo_q2+row["totale_mese"]: conto.importo_q2,
        importo_q3: row["mese"].between?(7, 9)? conto.importo_q3+row["totale_mese"]: conto.importo_q3, importo_q4: row["mese"].between?(10, 12)? conto.importo_q4+row["totale_mese"]: conto.importo_q4)
      end
    end
    client.close
  end

  desc "3) calcola dati per livelli superiori"
  task :livelli => :environment do
    puts "Task livelli: Calcolo e carico dati per conto per livelli superiori di environment #{Rails.env}"

    client = Mysql2::Client.new(:host => "#{host}", :username => "#{username}", :password => "#{password}", :database => "#{database}")
    anno = nil

    # calcolo il livello 4 sommando il livello 5
    client.query("select financial_plans.mandante, financial_plans.societa, financial_plans.anno, piano_finanziario_2016.tipo_conto, piano_finanziario_2016.livello, piano_finanziario_2016.voce,
    concat(substr(financial_plans.conto, 1, 13), '000')  as conto_liv, substr(financial_plans.conto, 1, 13) as conto_new, sum(financial_plans.importo) as importo_tot,
    sum(financial_plans.importo_01) as importo_tot_01, sum(financial_plans.importo_02) as importo_tot_02, sum(financial_plans.importo_03) as importo_tot_03,
    sum(financial_plans.importo_04) as importo_tot_04, sum(financial_plans.importo_05) as importo_tot_05, sum(financial_plans.importo_06) as importo_tot_06,
    sum(financial_plans.importo_07) as importo_tot_07, sum(financial_plans.importo_08) as importo_tot_08, sum(financial_plans.importo_09) as importo_tot_09,
    sum(financial_plans.importo_10) as importo_tot_10, sum(financial_plans.importo_11) as importo_tot_11, sum(financial_plans.importo_12) as importo_tot_12,
    sum(financial_plans.importo_q1) as importo_tot_q1, sum(financial_plans.importo_q2) as importo_tot_q2, sum(financial_plans.importo_q3) as importo_tot_q3,
    sum(financial_plans.importo_q4) as importo_tot_q4 from financial_plans
    JOIN piano_finanziario_2016 on concat(substr(financial_plans.conto, 1, 13), '000') = piano_finanziario_2016.conto and financial_plans.livello = 5
    group by financial_plans.anno, conto_liv").each do |row|
      if anno == row["anno"] or anno.nil?
        FinancialPlan.create(mandante: row["mandante"], societa: row["societa"], anno: row["anno"], conto: row["conto_liv"], importo: row["importo_tot"], tipo_conto: row["tipo_conto"], livello: tratta_livello(row["livello"]), voce: row["voce"], ricerca: row["voce"].downcase,
        importo_01: row["importo_tot_01"], importo_02: row["importo_tot_02"], importo_03: row["importo_tot_03"], importo_04: row["importo_tot_04"], importo_05: row["importo_tot_05"], importo_06: row["importo_tot_06"],
        importo_07: row["importo_tot_07"], importo_08: row["importo_tot_08"], importo_09: row["importo_tot_09"], importo_10: row["importo_tot_10"], importo_11: row["importo_tot_11"], importo_12: row["importo_tot_12"],
        importo_q1: row["importo_tot_q1"], importo_q2: row["importo_tot_q2"], importo_q3: row["importo_tot_q3"], importo_q4: row["importo_tot_q4"])
      end
    end
    # calcolo il livello 3 sommando il livello 4
    client.query("select financial_plans.mandante, financial_plans.societa, financial_plans.anno, piano_finanziario_2016.tipo_conto, piano_finanziario_2016.livello, piano_finanziario_2016.voce,
    concat(substr(financial_plans.conto, 1, 10), '00.000') as conto_liv, substr(financial_plans.conto, 1, 10) as conto_new, sum(financial_plans.importo) as importo_tot,
    sum(financial_plans.importo_01) as importo_tot_01, sum(financial_plans.importo_02) as importo_tot_02, sum(financial_plans.importo_03) as importo_tot_03,
    sum(financial_plans.importo_04) as importo_tot_04, sum(financial_plans.importo_05) as importo_tot_05, sum(financial_plans.importo_06) as importo_tot_06,
    sum(financial_plans.importo_07) as importo_tot_07, sum(financial_plans.importo_08) as importo_tot_08, sum(financial_plans.importo_09) as importo_tot_09,
    sum(financial_plans.importo_10) as importo_tot_10, sum(financial_plans.importo_11) as importo_tot_11, sum(financial_plans.importo_12) as importo_tot_12,
    sum(financial_plans.importo_q1) as importo_tot_q1, sum(financial_plans.importo_q2) as importo_tot_q2, sum(financial_plans.importo_q3) as importo_tot_q3,
    sum(financial_plans.importo_q4) as importo_tot_q4 from financial_plans
    JOIN piano_finanziario_2016 on concat(substr(financial_plans.conto, 1, 10), '00.000') = piano_finanziario_2016.conto and financial_plans.livello = 4
    group by financial_plans.anno, conto_liv").each do |row|
      if anno == row["anno"] or anno.nil?
        FinancialPlan.create(mandante: row["mandante"], societa: row["societa"], anno: row["anno"], conto: row["conto_liv"], importo: row["importo_tot"], tipo_conto: row["tipo_conto"], livello: tratta_livello(row["livello"]), voce: row["voce"], ricerca: row["voce"].downcase,
        importo_01: row["importo_tot_01"], importo_02: row["importo_tot_02"], importo_03: row["importo_tot_03"], importo_04: row["importo_tot_04"], importo_05: row["importo_tot_05"], importo_06: row["importo_tot_06"],
        importo_07: row["importo_tot_07"], importo_08: row["importo_tot_08"], importo_09: row["importo_tot_09"], importo_10: row["importo_tot_10"], importo_11: row["importo_tot_11"], importo_12: row["importo_tot_12"],
        importo_q1: row["importo_tot_q1"], importo_q2: row["importo_tot_q2"], importo_q3: row["importo_tot_q3"], importo_q4: row["importo_tot_q4"])
      end
    end
    # calcolo il livello 2 sommando il livello 3
    client.query("select financial_plans.mandante, financial_plans.societa, financial_plans.anno, piano_finanziario_2016.tipo_conto, piano_finanziario_2016.livello, piano_finanziario_2016.voce,
    concat(substr(financial_plans.conto, 1, 7), '00.00.000') as conto_liv, substr(financial_plans.conto, 1, 7) as conto_new, sum(financial_plans.importo) as importo_tot,
    sum(financial_plans.importo_01) as importo_tot_01, sum(financial_plans.importo_02) as importo_tot_02, sum(financial_plans.importo_03) as importo_tot_03,
    sum(financial_plans.importo_04) as importo_tot_04, sum(financial_plans.importo_05) as importo_tot_05, sum(financial_plans.importo_06) as importo_tot_06,
    sum(financial_plans.importo_07) as importo_tot_07, sum(financial_plans.importo_08) as importo_tot_08, sum(financial_plans.importo_09) as importo_tot_09,
    sum(financial_plans.importo_10) as importo_tot_10, sum(financial_plans.importo_11) as importo_tot_11, sum(financial_plans.importo_12) as importo_tot_12,
    sum(financial_plans.importo_q1) as importo_tot_q1, sum(financial_plans.importo_q2) as importo_tot_q2, sum(financial_plans.importo_q3) as importo_tot_q3,
    sum(financial_plans.importo_q4) as importo_tot_q4 from financial_plans
    JOIN piano_finanziario_2016 on concat(substr(financial_plans.conto, 1, 7), '00.00.000') = piano_finanziario_2016.conto and financial_plans.livello = 3
    group by financial_plans.anno, conto_liv").each do |row|
      if anno == row["anno"] or anno.nil?
        FinancialPlan.create(mandante: row["mandante"], societa: row["societa"], anno: row["anno"], conto: row["conto_liv"], importo: row["importo_tot"], tipo_conto: row["tipo_conto"], livello: tratta_livello(row["livello"]), voce: row["voce"], ricerca: row["voce"].downcase,
        importo_01: row["importo_tot_01"], importo_02: row["importo_tot_02"], importo_03: row["importo_tot_03"], importo_04: row["importo_tot_04"], importo_05: row["importo_tot_05"], importo_06: row["importo_tot_06"],
        importo_07: row["importo_tot_07"], importo_08: row["importo_tot_08"], importo_09: row["importo_tot_09"], importo_10: row["importo_tot_10"], importo_11: row["importo_tot_11"], importo_12: row["importo_tot_12"],
        importo_q1: row["importo_tot_q1"], importo_q2: row["importo_tot_q2"], importo_q3: row["importo_tot_q3"], importo_q4: row["importo_tot_q4"])
      end
    end
    # calcolo il livello 1 sommando il livello 2
    client.query("select financial_plans.mandante, financial_plans.societa, financial_plans.anno, piano_finanziario_2016.tipo_conto, piano_finanziario_2016.livello, piano_finanziario_2016.voce,
    concat(substr(financial_plans.conto, 1, 4), '00.00.00.000') as conto_liv, substr(financial_plans.conto, 1, 4) as conto_new, sum(financial_plans.importo) as importo_tot,
    sum(financial_plans.importo_01) as importo_tot_01, sum(financial_plans.importo_02) as importo_tot_02, sum(financial_plans.importo_03) as importo_tot_03,
    sum(financial_plans.importo_04) as importo_tot_04, sum(financial_plans.importo_05) as importo_tot_05, sum(financial_plans.importo_06) as importo_tot_06,
    sum(financial_plans.importo_07) as importo_tot_07, sum(financial_plans.importo_08) as importo_tot_08, sum(financial_plans.importo_09) as importo_tot_09,
    sum(financial_plans.importo_10) as importo_tot_10, sum(financial_plans.importo_11) as importo_tot_11, sum(financial_plans.importo_12) as importo_tot_12,
    sum(financial_plans.importo_q1) as importo_tot_q1, sum(financial_plans.importo_q2) as importo_tot_q2, sum(financial_plans.importo_q3) as importo_tot_q3,
    sum(financial_plans.importo_q4) as importo_tot_q4 from financial_plans
    JOIN piano_finanziario_2016 on concat(substr(financial_plans.conto, 1, 4), '00.00.00.000') = piano_finanziario_2016.conto and financial_plans.livello = 2
    group by financial_plans.anno, conto_liv").each do |row|
      if anno == row["anno"] or anno.nil?
        FinancialPlan.create(mandante: row["mandante"], societa: row["societa"], anno: row["anno"], conto: row["conto_liv"], importo: row["importo_tot"], tipo_conto: row["tipo_conto"], livello: tratta_livello(row["livello"]), voce: row["voce"], ricerca: row["voce"].downcase,
        importo_01: row["importo_tot_01"], importo_02: row["importo_tot_02"], importo_03: row["importo_tot_03"], importo_04: row["importo_tot_04"], importo_05: row["importo_tot_05"], importo_06: row["importo_tot_06"],
        importo_07: row["importo_tot_07"], importo_08: row["importo_tot_08"], importo_09: row["importo_tot_09"], importo_10: row["importo_tot_10"], importo_11: row["importo_tot_11"], importo_12: row["importo_tot_12"],
        importo_q1: row["importo_tot_q1"], importo_q2: row["importo_tot_q2"], importo_q3: row["importo_tot_q3"], importo_q4: row["importo_tot_q4"])
      end
    end
    # calcolo il livello 0 sommando il livello 1 (totali entrate e uscite)
    client.query("select financial_plans.mandante, financial_plans.societa, financial_plans.anno, concat(substr(financial_plans.conto, 1, 2), '0.00.00.00.000') as conto_liv,
    substr(financial_plans.conto, 1, 1) as tipo_conto, sum(financial_plans.importo) as importo_tot,
    sum(financial_plans.importo_01) as importo_tot_01, sum(financial_plans.importo_02) as importo_tot_02, sum(financial_plans.importo_03) as importo_tot_03,
    sum(financial_plans.importo_04) as importo_tot_04, sum(financial_plans.importo_05) as importo_tot_05, sum(financial_plans.importo_06) as importo_tot_06,
    sum(financial_plans.importo_07) as importo_tot_07, sum(financial_plans.importo_08) as importo_tot_08, sum(financial_plans.importo_09) as importo_tot_09,
    sum(financial_plans.importo_10) as importo_tot_10, sum(financial_plans.importo_11) as importo_tot_11, sum(financial_plans.importo_12) as importo_tot_12,
    sum(financial_plans.importo_q1) as importo_tot_q1, sum(financial_plans.importo_q2) as importo_tot_q2, sum(financial_plans.importo_q3) as importo_tot_q3,
    sum(financial_plans.importo_q4) as importo_tot_q4
    from financial_plans where financial_plans.livello = 1 group by financial_plans.anno, tipo_conto").each do |row|
      if anno == row["anno"] or anno.nil?
        FinancialPlan.create(mandante: row["mandante"], societa: row["societa"], anno: row["anno"], conto: row["conto_liv"], importo: row["importo_tot"], tipo_conto: row["tipo_conto"], livello: 0, voce: row["tipo_conto"]=="E"?"Totale Entrate":"Totale Uscite", ricerca: row["tipo_conto"]=="E"?"totale entrate":"totale uscite",
        importo_01: row["importo_tot_01"], importo_02: row["importo_tot_02"], importo_03: row["importo_tot_03"], importo_04: row["importo_tot_04"], importo_05: row["importo_tot_05"], importo_06: row["importo_tot_06"],
        importo_07: row["importo_tot_07"], importo_08: row["importo_tot_08"], importo_09: row["importo_tot_09"], importo_10: row["importo_tot_10"], importo_11: row["importo_tot_11"], importo_12: row["importo_tot_12"],
        importo_q1: row["importo_tot_q1"], importo_q2: row["importo_tot_q2"], importo_q3: row["importo_tot_q3"], importo_q4: row["importo_tot_q4"])
      end
    end
    client.close
  end

  desc "4) riporta campo ricerca su tutti i livelli"
  task :ricerca => :environment do
    puts "Task ricerca: Riporto la descrizione dei conti dei livelli superiori nel campo di ricerca di quelli inferiori (in minuscolo) di environment #{Rails.env}"

    client = Mysql2::Client.new(:host => "#{host}", :username => "#{username}", :password => "#{password}", :database => "#{database}")

    client.query("select financial_plans.id, financial_plans.anno, financial_plans.livello, financial_plans.conto, piano_finanziario_2016.conto as conto_sup,  piano_finanziario_2016.voce, financial_plans.ricerca, financial_plans.voce as voce_old from financial_plans join piano_finanziario_2016 on concat(substr(financial_plans.conto, 1, 4), '00.00.00.000') = piano_finanziario_2016.conto and financial_plans.livello > 1").each do |row|
      conto = FinancialPlan.find(row["id"])
      conto.update(ricerca: row["voce_old"].downcase << " " << row["voce"].downcase)
    end
    client.query("select financial_plans.id, financial_plans.anno, financial_plans.livello, financial_plans.conto, piano_finanziario_2016.conto as conto_sup,  piano_finanziario_2016.voce, financial_plans.ricerca, financial_plans.voce as voce_old from financial_plans join piano_finanziario_2016 on concat(substr(financial_plans.conto, 1, 7), '00.00.000') = piano_finanziario_2016.conto and financial_plans.livello > 2").each do |row|
      conto = FinancialPlan.find(row["id"])
      conto.update(ricerca: row["ricerca"] << " " << row["voce"].downcase)
    end
    client.query("select financial_plans.id, financial_plans.anno, financial_plans.livello, financial_plans.conto, piano_finanziario_2016.conto as conto_sup,  piano_finanziario_2016.voce, financial_plans.ricerca, financial_plans.voce as voce_old from financial_plans join piano_finanziario_2016 on concat(substr(financial_plans.conto, 1, 10), '00.000') = piano_finanziario_2016.conto and financial_plans.livello > 3").each do |row|
      conto = FinancialPlan.find(row["id"])
      conto.update(ricerca: row["ricerca"] << " " << row["voce"].downcase)
    end
    client.query("select financial_plans.id, financial_plans.anno, financial_plans.livello, financial_plans.conto, piano_finanziario_2016.conto as conto_sup,  piano_finanziario_2016.voce, financial_plans.ricerca, financial_plans.voce as voce_old from financial_plans join piano_finanziario_2016 on concat(substr(financial_plans.conto, 1, 13), '000') = piano_finanziario_2016.conto and financial_plans.livello > 4").each do |row|
      conto = FinancialPlan.find(row["id"])
      conto.update(ricerca: row["ricerca"] << " " << row["voce"].downcase)
    end
    client.close
  end

  desc "5) richiama in cascata tutti gli aggiornamenti"
  # es.: rake etl:daily_update["18/07/2017"]
  task :daily_update, [:giorno] do |t, args|
    Rake::Task["etl:csv_import"].reenable
    Rake::Task["etl:dati"].reenable
    Rake::Task["etl:livelli"].reenable
    Rake::Task["etl:ricerca"].reenable
    Rake::Task["etl:csv_import"].invoke("#{args[:giorno]}")
    Rake::Task["etl:dati"].invoke
    Rake::Task["etl:livelli"].invoke
    Rake::Task["etl:ricerca"].invoke
  end

  desc "6) trasferisce i file da elaborare"
  # trasferisce il file da elaborare dal server remoto
  task :get_file do
    puts "Task get_file: Trasferisco il file da elaborare dal server remoto"
    # creo directory di lavoro all stesso livello del progetto
    # es. /home/rails/etl/tmp
    tmp = "#{root}/../etl/tmp/"
    FileUtils.mkdir_p "#{tmp}"
    # entro nella directory tmp
    FileUtils.cd("#{tmp}")
    # scarico tutti i fie presenti nella directory remota etl (di solito uno solo)
    cmd = "for file in $(curl -s #{url_get} |
                      grep href |
                      sed  's/.*href=\"//' |
                      sed  's/\".*//' |
                      grep '^[a-zA-Z].*'); do
        curl -s -O #{url_get}$file
    done"
    system! cmd
  end

  desc "7) esegue aggiornamento automatico giornaliero"
  # trasferisce il file dal server remoto
  # crea elenco di file da elaborare
  # se pieno e non elaborato richiama agggionamenti
  # salva nome del file aggiornato
  task :auto_update do
    data = DateTime.now.strftime("%d/%m/%Y alle ore %I:%M%p")
    puts "====================================================================="
    puts "Task auto_update: Elaborazione del giorno #{data}"
    # richiama il trasferimento dei file da elaborare
    Rake::Task["etl:get_file"].invoke
    puts "Directory di lavoro: "+ FileUtils.pwd
    # crea elenco file da elaborare in array
    file_etl = Dir.entries(".")
    file_etl.delete(".")
    file_etl.delete("..")
    if file_etl.size < 1
      puts "Non ci sono file da elaborare"
    else
      file_etl.each {|file_name|
        puts "Verifico il nome dell'ultimo file elaborato nel file: #{root}/../etl/lastfile.txt"
        if File.exist?("#{root}/../etl/lastfile.txt")
          lastfile = File.new("#{root}/../etl/lastfile.txt", "r+")
        else
          lastfile = File.new("#{root}/../etl/lastfile.txt", "w+")
        end
        ultimo = lastfile.gets
        ultimo.chomp! if !ultimo.nil?
        # controllo se il file è già stato elaborato
        if ultimo == file_name or ultimo > file_name
          puts "File #{file_name} già elaborato"
          # sposto il file da elaborare da etl/tmp a etl/
          FileUtils.mv "#{root}/../etl/tmp/#{file_name}", "#{root}/../etl/#{file_name}"
        else
          puts "Elaboro #{file_name}"
          # estrae dal nome del file la data e la societa'
          s = file_name.split("_")
          societa = s[2]
          data = s[3].sub!(".csv","")
          puts "società: #{societa} data: #{data}"
          # sposto il file da elaborare da etl/tmp a etl/
          FileUtils.mv "#{root}/../etl/tmp/reversali_mandati_#{societa}_#{data}.csv", "#{root}/../etl/reversali_mandati_#{societa}_#{data}.csv"
          # richiama elaborazione del file gira la data per poter richiamare il task manualmente
          datagirata = DateTime.strptime("#{data}", '%Y.%m.%d').strftime('%d/%m/%Y')
          puts "datagirata: #{datagirata}"
          Rake::Task["etl:daily_update"].reenable
          Rake::Task["etl:daily_update"].invoke("#{datagirata}")
          # aggiorno il nome dell'ultimo file elaborato
          lastfile.close
          lastfile = File.new("#{root}/../etl/lastfile.txt", "w")
          lastfile.puts(file_name)
          lastfile.close
          puts "_____________________________________________________"
        end
      }
    end
    puts "====================================================================="
  end

end
