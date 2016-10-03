class FinancialPlan < ApplicationRecord

  #Metodi di classe
  class << self
    def simple_search(mandante, societa, anno, tipo_conto, livello, conto, voce, ricerca, sort_column, sort_order, page, per_page)

      if mandante.nil?    then mandante    = '130'   end
      if societa.nil?     then societa     = '1000'  end

      if sort_column.nil? then sort_column = 'conto' end
      if sort_order.nil?  then sort_order  = 'ASC'   end

      sort = case sort_column
               when 'conto' then
                 sort_column + ' ' + sort_order
               when 'tipo_conto' then
                 sort_column + ' ' + sort_order + ', conto'
               when 'anno' then
                 'anno' + ' ' + sort_order + ', conto'
               when 'importo' then
                 sort_column + ' ' + sort_order
             end

      order(sort).where('mandante LIKE ? and societa LIKE ? and anno LIKE ? and tipo_conto LIKE ? and livello LIKE ? and conto LIKE ? and voce LIKE ? and ricerca LIKE ?',
      "%#{mandante}%", "%#{societa}%", "%#{anno}%", "%#{tipo_conto}%", "%#{livello}%", "#{conto}%", "%#{voce}%", "%#{ricerca}%").paginate(page: page, per_page: per_page)
    end

    def search(mandante, societa, anno, tipo_conto, livello, conto, voce, ricerca, sort_column, sort_order, page, per_page)
      if mandante.nil?    then mandante    = '130'          end
      if societa.nil?     then societa     = '1000'         end

      if anno.nil?        then anno        = Time.now.year  end
      anno_prec           =    anno.to_i-1

      if sort_column.nil? then sort_column = 'conto' end
      if sort_order.nil?  then sort_order  = 'ASC'   end

      sort = case sort_column
               when 'conto' then
                 sort_column + ' ' + sort_order
               when 'tipo_conto' then
                 sort_column + ' ' + sort_order + ', conto'
               when 'anno' then
                 'anno' + ' ' + sort_order + ', conto'
               when 'importo' then
                 sort_column + ' ' + sort_order
             end

      self.paginate_by_sql(["SELECT * FROM
      (SELECT * FROM financial_plans
      WHERE mandante = ? and societa = ? and anno = ? and tipo_conto LIKE ? and livello LIKE ? and conto LIKE ? and voce LIKE ? and ricerca LIKE ?) t1
      LEFT JOIN
      (SELECT mandante as mandante_prec, societa as societa_prec, anno as anno_prec, conto as conto_prec, importo as importo_prec,
      importo_01 as importo_01_prec, importo_02 as importo_02_prec, importo_03 as importo_03_prec, importo_04 as importo_04_prec, importo_05 as importo_05_prec, importo_06 as importo_06_prec,
      importo_07 as importo_07_prec, importo_08 as importo_08_prec, importo_09 as importo_09_prec, importo_10 as importo_10_prec, importo_11 as importo_11_prec, importo_12 as importo_12_prec,
      importo_q1 as importo_q1_prec, importo_q2 as importo_q2_prec, importo_q3 as importo_q3_prec, importo_q4 as importo_q4_prec
      FROM financial_plans WHERE anno = ?) t2
      ON t2.mandante_prec = t1.mandante and t2.societa_prec = t1.societa and t2.conto_prec = t1.conto order by #{sort}",
      "#{mandante}", "#{societa}", "#{anno}", "%#{tipo_conto}%", "%#{livello}%", "#{conto}%", "%#{voce}%", "%#{ricerca}%", "#{anno_prec}"],
      page: page, per_page: per_page)

    end

  end

end
