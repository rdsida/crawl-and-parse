# frozen_string_literal: true

class SdCrawler < BaseCrawler
  protected

  def _set_up_page
    @driver.page_source =~ /iframe src="([^"]+)/
    crawl_page $1
    element = wait.until {
      @driver.find_elements(class: 'themableBackgroundColor').select {|i| i.text == 'Tables'}.first
    }
    element.click
    @s = @driver.find_elements(class: 'tableExContainer').map {|i| i.text}.select {|i| i=~/Total Negative Cases/}.first
  end

  def _find_positive
    if @s.gsub('*','').gsub(',','') =~ /Cases\n # of Cases\nActive Cases\nCurrently Hospitalized\nRecovered\nTotal Positive Cases\nTotal Negative Cases\nEver Hospitalized\nDeaths\n\d+\n\d+\n\d+\n(\d+)\n(\d+)\n(\d+)\n(\d+)/
      @results[:positive] = $1.to_i
      @results[:negative] = $2.to_i
      @results[:hospitalized] = $3.to_i
      @results[:deaths] = $4.to_i
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

