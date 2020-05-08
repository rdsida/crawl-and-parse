# frozen_string_literal: true

# Kentucky
# https://govstatus.egov.com/kycovid19
class KyCrawler < BaseCrawler
  protected

  def _set_up_page
    wait.until { @driver.find_element(class: 'info-card') }

    @info_cards = Nokogiri::HTML.parse(@driver.page_source)
                                .css('.info-card')
                                .to_a
  end

  def _find_positive
    @results[:positive] = get_number('Total Positive')
  end

  def _find_tested
    @results[:tested] = get_number('Total Tested')
  end

  def _find_deaths
    @results[:deaths] = get_number('Deaths')
  end

  def _find_recovered
    @results[:recovered] = get_number('Recovered')
  end

  # _find_hospitalized

  # _find_counties

  # _find_towns

  private

  # Take a search term, return an integer
  def get_number(query)
    string_to_i find_card(query).content
                                .strip
                                .match(/[\d,]+$/)[0]
  end

  # This assumes there will only be one match.
  def find_card(query)
    @info_cards.filter { |card| card.content.include? query }
               .first
  end
end
