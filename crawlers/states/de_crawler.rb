# frozen_string_literal: true

# Delaware
# https://coronavirus.delaware.gov/
class DeCrawler < BaseCrawler
  protected

  # Place results in @results[:statistic], i.e. @results[:positive]
  # Skip if not available/applicable.

  def _set_up_page
    wait.until { @driver.find_element id: 'data-dashboard' }
    @driver.switch_to.frame('data-dashboard')
  end

  def _find_positive
    @results[:positive] = get_number 'Positive'
  end

  # if :tested is not available, find :negative
  def _find_tested
    @results[:negative] = get_number 'Negative'
  end

  def _find_deaths
    @results[:deaths] = get_number 'Deaths'
  end

  def _find_recovered
    @results[:recovered] = get_number 'Recovered'
  end

  def _find_hospitalized
    @results[:hospitalized] = get_number 'Hospitalizations'
  end

  # _find_counties

  # _find_towns

  private

  # Assumes only one card will contain your query, and that the first value is
  # the one you want.
  def get_number(query)
    string_to_i cards.filter { |c| c.to_s.include? query }
                     .first
                     .at_css('.c-summary-metric__value')
                     .text
  end

  def cards
    @cards ||= Nokogiri::HTML.parse(@driver.page_source)
                             .css('.c-summary-metric')
                             .to_a
  end
end
