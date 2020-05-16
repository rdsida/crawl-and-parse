# frozen_string_literal: true

class PrCrawler < BaseCrawler
  protected

  def _find_positive
    if @driver.find_elements(class: 'ms-rteTable-10').map {|i| i.text}.select {|i| i=~/muertes/i}.first.gsub(',','') =~ /(\d+)\n\d+\n\d+\n(\d+)$/
      @results[:positive] = $1.to_i
      @results[:deaths] = $2.to_i
    else
      @errors << 'parse failed'
    end
  end

  # _find_tested
  # if :tested is not available, find :negative

  # _find_deaths

  # _find_recovered

  # _find_hospitalized

  # _find_counties

  # _find_towns
end

