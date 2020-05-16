# frozen_string_literal: true

# Oklahoma
# https://coronavirus.health.ok.gov/
class OkCrawler < BaseCrawler
  # We have to override the call method because we need to call _find_tested
  # last. This is a big red flag; should refactor later.
  def call
    _set_up_page

    parse_dashboard

    _find_tested
    _check_results
    @results
  end

  protected

  def _set_up_page
    # The iframe is lazy-loaded, meaning we have to scroll it into view:
    @driver.execute_script 'window.scroll(0,1000)'

    wait.until { dash_loaded }

    @driver.switch_to.frame(dashboard)
  end

  def _find_tested
    @driver.navigate.to 'https://coronavirus.health.ok.gov/executive-order-reports'

    @results[:tested] = latest_report.get_int(
      /Total Number of Specimens Tested to Date([\d,]+)/
    )
  end

  # _find_hospitalized
  # _find_counties
  # _find_towns

  private

  def parse_dashboard
    dashboard_query_hash.each_pair do |key, query|
      @results[key] = get_dashboard_number(query)
    end
  end

  # Pair results keys with appropriate get_dashboard_number args
  def dashboard_query_hash
    {
      positive: 'OK Cases',
      deaths: 'OK Deaths',
      recovered: 'OK Recovered'
    }
  end

  # Returns an array of cards with interesting stats in them.
  def grid_items
    @driver.find_elements(css: 'div.react-grid-item')
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

  def latest_report
    @latest_report ||= PdfParser.new latest_report_uri, 'ok'
  end

  def latest_report_uri
    reports = wait.until do
      @driver.find_elements(xpath: '//a[contains(@type, "application/pdf")]')
    end
    reports.first.attribute('href')
  end

  def get_dashboard_number(query)
    item = wait.until do
      # Find an item which starts with the given query
      grid_items.filter { |i| i.text.index(query)&.zero? }
                .first
    end

    # Rejigger it into an int
    string_to_i item.text
                    .delete_prefix(query)
                    .strip
                    .split
                    .first
  end
end
