# frozen_string_literal: true

class NeCrawler < BaseCrawler
  protected

  def _find_positive
    if url = @driver.page_source.scan(/https:\/\/arcg.is[^'"]+/).first
    else
      @errors << 'missing url'
      return
    end
    crawl_page url
    wait.until {
      @driver.find_element(class: 'dashboard-page').text.gsub(',','') =~ /Total Positive Cases\n(\d+)\nTotal Tested\n(\d+)\nTested: Not Detected\n\d+\n.*\nDeaths\n(\d+)\n/
    }
    @results[:positive] = $1.to_i
    @results[:tested] = $2.to_i
    @results[:deaths] = $3.to_i
  end

  # _find_tested
  # if :tested is not available, find :negative

  # _find_deaths

  # _find_recovered

  # _find_hospitalized

  # _find_counties

  # _find_towns
end

