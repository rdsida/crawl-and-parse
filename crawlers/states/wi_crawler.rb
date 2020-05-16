# frozen_string_literal: true

class WiCrawler < BaseCrawler
  protected

  def _set_up_page
    @s = @driver.find_elements(id: 'covid-state-table')[0].text.gsub(',','')
  end

  def _find_positive
    if @s =~ /Positive Test Results (\d+)\n/
      @results[:positive] = $1.to_i
    end
  end

  def _find_tested
    if @s =~ /Negative Test Results (\d+)\n/
      @results[:negative] = $1.to_i
    end
  end

  def _find_deaths
    if @s =~ /Deaths (\d+)/
      @results[:deaths] = $1.to_i
    end
  end

  # _find_recovered

  # _find_hospitalized

  # _find_counties

  # _find_towns
end

