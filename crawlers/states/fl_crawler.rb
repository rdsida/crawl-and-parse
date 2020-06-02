# frozen_string_literal: true

class FlCrawler < BaseCrawler
  protected

  def _find_positive
    wait.until {
      s = @driver.find_elements(class: 'inner--box').map {|i| i.text.gsub(',','')}.select {|i| i=~/Positive Residents/}[0]
"Positive Residents\n56001\nPositive Non-Residents\n1446\nTotal Cases\n57447\nDeaths\n2530\nPositive Residents Out of State\n8"
      if s =~ /Total Cases\s(\d+)\sDeaths\s(\d+)/
        @results[:positive] = $1.to_i
        @results[:deaths] = $2.to_i 
      else
        false
      end
    }
  end

  def _find_tested
    wait.until {
      s = @driver.find_elements(class: 'inner--box').map {|i| i.text.gsub(',','')}.select {|i| i=~/Testing Results/}[0]
      if s =~ /\nTotal\n(\d+)/
        @results[:tested] = $1.to_i
      else
        false
      end
    }
  end  

  # _find_recovered

  # _find_hospitalized

  # _find_counties

  # _find_towns
end

