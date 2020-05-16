# frozen_string_literal: true

class FlCrawler < BaseCrawler
  protected

  def _find_positive
    s = @driver.find_elements(class: 'tablepress').map {|i| i.text.gsub(',','')}.select {|i| i=~/Positive (\d+)\nNegative (\d+)\nTotal (\d+)/}.first
    if s =~ /Positive (\d+)\nNegative (\d+)\nTotal (\d+)/
      @results[:positive] = $1.to_i
      @results[:negative] = $2.to_i
      @results[:tested] = $3.to_i 
    end
  end

  # _find_tested
  # if :tested is not available, find :negative

  def _find_deaths
    s = @driver.find_elements(class: 'stat--box').map {|i| i.text.gsub(',','')}.select {|i| i=~/Deaths\n(\d+)/}.first
    if s =~ /Deaths\n(\d+)/
      @results[:deaths] = $1.to_i
    end
  end

  # _find_recovered

  # _find_hospitalized

  # _find_counties

  # _find_towns
end

