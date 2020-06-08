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
    cards = @driver.find_elements(class: 'c-dashboard-card__content')

    @positive_data = cards.
                     find { |t| t.text =~ /State of Delaware/ }.
                     text.
                     tr(',','').
                     gsub(/\s+/,' ')
    @other_data = cards.
                     find { |t| t.text =~ /\d+\s?Hospitalized/ }.
                     text.
                     tr(',','').
                     gsub(/\s+/,' ')
    testing_url = @driver.
                    find_elements(
                      class: 'c-summary-metric__link'
                    ).
                    find { |t| t.text =~ /All Tests/ }.
                    find_element(xpath: "./..").
                    attribute('href')
    @driver.navigate.to(testing_url)
    @testing_data =  @driver.
                        find_elements(class: 'c-dashboard-card').
                        find { |t| t.text =~ /Total Persons Tested/ }.
                        text.
                        tr(',','').
                        gsub(/\s+/,' ')
  end

  def _find_positive
    @results[:positive] = @positive_data.match(/State of Delaware (\d+)/)[1].to_i
  end

  # if :tested is not available, find :negative
  def _find_tested
    @results[:tested] = @testing_data.match(/State of Delaware (\d+)/)[1].to_i
  end

  def _find_deaths
    @results[:deaths] = @other_data.match(/(\d+) Deaths/)[1].to_i
  end

  def _find_recovered
    @results[:recovered] = @other_data.match(/(\d+) Recovered/)[1].to_i
  end

  def _find_hospitalized
    @results[:hospitalized] = @other_data.match(/(\d+) Hospitalized/)[1].to_i
  end

  def _find_counties
    new_castle_regex = %r(/New Castle County (\d+)/)
    @results[:counties] << {
      name: 'New Castle County',
      positive: new_castle_regex.match(@positive_data),
      tested: new_castle_regex.match(@testing_data),
    }
    kent_county = %r(/Kent County (\d+)/)
    @results[:counties] << {
      name: 'Kent County',
      positive: kent_county.match(@positive_data),
      tested: kent_county.match(@testing_data),
    }
    sussex_county = %r(/Sussex County (\d+)/)
    @results[:counties] << {
      name: 'Sussex County',
      positive: sussex_county.match(@positive_data),
      tested: sussex_county.match(@testing_data),
    }
  end

  # _find_towns
end
