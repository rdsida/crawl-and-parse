class RiCrawler < BaseCrawler
  protected

  def _set_up_page
    wait.until do
      @driver.find_element(id: 'main-region').text =~ /Total COVID-19 Positive\n\d/
    end
    true
  end

  def _find_positive
    @results[:positive] = /Total COVID-19 Positive(\d+)/.match(page_elements)[1]&.to_i
  end

  def _find_tested
    @results[:tested] = /Total Covid-19 Tests(\d+)/.match(page_elements)[1]&.to_i
  end

  def _find_deaths
    @results[:deaths] = /COVID-19 Fatalities(\d+)/.match(page_elements)[1]&.to_i
  end

  def _find_hospitalized
    @results[:hospitalized] = /Currently Hospitalized(\d+)/.match(page_elements)[1]&.to_i
  end

  private

  def page_elements
    @driver.find_element(id: 'main-region').text.delete("\n,")
  end
end
