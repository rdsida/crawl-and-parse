# frozen_string_literal: true

# In the main crawler class, replace applicable parse_XX method with:

# Replace XX with state code, i.e. Wi or Ca. Capitalize first letter
class NvCrawler < BaseCrawler
  def call
    _set_up_page

    _parse_test_results
    _find_hospitalized

    _check_results

    @results
  end

  private

  # Place results in @results[:statistic], i.e. @results[:positive]
  # Skip if not available/applicable.

  def _set_up_page
    # Scroll down a bit in case it's lazy loaded
    @driver.execute_script('window.scroll(0,1000)')

    # Luckily there's only one iframe
    @driver.switch_to.frame(@driver.find_element(tag_name: 'iframe'))

    # The dashboard is given in several pages, and the selected page is
    # persistent between page loads.
    go_to_page 'Test Results'
  end

  def go_to_page(name)
    wait.until { open_nav_menu }
    wait.until { @driver.find_element(link_text: name) }.click
  end

  def open_nav_menu
    @driver.find_element(css: 'a.middleText').click
    true
  rescue Selenium::WebDriver::Error::ElementNotInteractableError,
         Selenium::WebDriver::Error::NoSuchElementError
    false
  end

  def _parse_test_results
    query_hash.each_pair do |key, query|
      @results[key] = get_int query
    end
  end

  # Hostpitalized nubmers are on a different page, in a graph, split into
  # suspected and confirmed.
  def _find_hospitalized
    go_to_page 'Hospitalizations'

    @results[:hospitalized] = parse_graph('Confirmed') +
                              parse_graph('Suspected')
  end

  def query_hash
    {
      positive: 'Positive',
      # negative: 'Negative', # Only collect negative if tested is unavailable
      tested: 'People Tested', # Total Tests Performed is available as well
      deaths: 'Deaths Statewide'
    }
  end

  def get_int(query)
    string = wait.until do
      cards.filter { |card| card.include? query }
          &.first
          &.delete_suffix(query)
    end

    string_to_i string
  end

  def cards
    @driver.find_elements(css: 'svg.card').map(&:text)
  rescue Selenium::WebDriver::Error::NoSuchElementError
    []
  end

  # Graph on 'Hospitalized' page
  def graph_bars
    @driver.find_elements(css: 'rect.column.setFocusRing')
  rescue Selenium::WebDriver::Error::NoSuchElementError
    []
  end

  def parse_graph(query)
    wait.until { graph_bars.any? }

    bars = graph_bars.filter do |bar|
      bar.attribute('aria-label').include? query
    end

    string_to_i bars.last.attribute('aria-label').match(/([\d,]+)\.$/)[1]
  end

  # _find_counties

  # _find_towns
end
