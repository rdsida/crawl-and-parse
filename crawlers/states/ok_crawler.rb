# frozen_string_literal: true

# Oklahoma
# https://coronavirus.health.ok.gov/
class OkCrawler < BaseCrawler
  protected

  # Place results in @results[:statistic], i.e. @results[:positive]
  # Skip if not available/applicable.

  def _set_up_page
    # The iframe is lazy-loaded, meaning we have to scroll it into view:
    @driver.execute_script 'window.scroll(0,1000)'
    wait.until { dash_loaded }

    @driver.switch_to.frame(dashboard)
    # The dashboard loads separately, we need to wait until it finishes
    wait.until { grid_items.any? }
  end

  def _find_positive
    @results[:positive] = get_number 'OK Cases'
  end

  # _find_tested
  # if :tested is not available, find :negative
  # Neither are reported as far as I can tell.

  def _find_deaths
    @results[:deaths] = get_number 'OK Deaths'
  end

  def _find_recovered
    @results[:recovered] = get_number 'OK Recovered'
  end

  # _find_hospitalized

  # _find_counties

  # _find_towns
  private

  def get_number(query)
    string_to_i grid_items.filter { |i| i.text.index(query)&.zero? }
                          .first.text
                          .delete_prefix(query).strip
                          .split.first
  end

  # Seems to be the cleanest way to pick out data elements
  def grid_items
    Nokogiri::HTML.parse(@driver.page_source)
                  .css('div.react-grid-item')
                  .to_a
  end

  def dash_loaded
    dashboard&.attribute(:class)&.include?('b-loaded')
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end

  def dashboard
    @driver.find_element xpath:
      "//iframe[contains(@src, 'https://looker-dashboards.ok.gov')]"
  end
end
