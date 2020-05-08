# frozen_string_literal: true

# Crawl Alaska
class AkCrawler < BaseCrawler
  protected

  def _set_up_page
    url = @driver.page_source
                 .scan(%r{https[^'"]+arcgis\.com/apps/opsdashboard[^'"]+})[0]
    @driver.navigate.to(url)
  end

  def _find_positive
    w = /Total Cases(\d+)/.match(_page_elements)
    return unless w

    @results[:positive] = w[1].to_i
  end

  def _find_tested
    # Turns out the 'combined cumulative' graph is in the DOM, even if the graph
    # isn't displayed. The aria-labels look like this:
    # "Combined Cumulative May 06, 2020 24,341"
    value = Nokogiri::HTML.parse(@driver.page_source)
                          .css('.amcharts-graph-bullet')
                          .to_a
                          .filter { |b| b['aria-label'].include? 'Cumulative' }
                          .last['aria-label'] # Presumably we want the last one
                          .match(/[\d,]+$/)[0] # Number at the end

    @results[:tested] = string_to_i(value)
  end

  def _find_deaths
    w = /Total Deaths(\d+)/.match(_page_elements)
    return unless w

    @results[:deaths] = w[1].to_i
  end

  def _find_recovered
    w = /Total Recovered Cases(\d+)/.match(_page_elements)
    return unless w

    @results[:recovered] = w[1].to_i
  end

  def _find_hospitalized
    w = /Total Hospitalizations(\d+)/.match(_page_elements)
    return unless w

    @results[:hospitalized] = w[1].to_i
  end

  private

  def _page_elements
    @_page_elements ||= wait.until do
      @driver.find_element(class: 'claro')
    end.text.tr("\n", '')
  end
end
