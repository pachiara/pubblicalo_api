class Population < ApplicationRecord

  #Metodi di classe
  class << self
    def search(code, year)
      if code.nil?     then code    = '10'           end   # codice istat Lombardia
      if year.nil?     then year    = Time.now.year  end   # anno in corso
      where('code = ?  AND year = ?', "#{code}", "#{year}")
    end
  end

end
