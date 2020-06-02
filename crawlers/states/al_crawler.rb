# frozen_string_literal: true

class AlCrawler < BaseCrawler

  protected

  def _set_up_page
    url = wait.until {
      @driver.page_source[/[^'"]+alpublichealth.maps.arcgis.com[^'"]+/]
    }
    return unless url
    @driver.navigate.to(url)
  end

  def _find_positive
    w = /CASES(\d+(,\d+)*CONFIRMED)?/.match(_page_elements)
    return unless w && w[1]
    @results[:positive] = w[1].tr(',', '').to_i
  end

  def _find_tested
    w = /TOTAL TESTED(\d+(,\d+)*)?/.match(_page_elements)
    return unless w && w[1]
    @results[:tested] = w[1].tr(',', '').to_i
  end

  def _find_deaths
    w = /DEATHS(\d+(,\d+)*)?/.match(_page_elements)
    return unless w && w[1]
    @results[:deaths] = w[1].tr(',', '').to_i
  end

  def _find_hospitalized
    #w = /TOTAL HOSPITALIZATIONSSINCE \d+\/\d+\/\d{4}(\d+(,\d+)*)?/.match(_page_elements)
    #return unless w
    #@results[:hospitalized] = w[1].tr(',', '').to_i
  end

  private

  def _page_elements
    @_page_elements ||= wait.until { _dashboard_page }
                            .text
                            .delete("\n")
  end

  def _dashboard_page
    return unless _loading_finished

    @driver.find_element(class: 'dashboard-page')
  end

  # The loading animations are the only elements with a 'spin' class.
  def _loading_finished
    @driver.find_element(class: 'dashboard-page') &&
      !@driver.find_element(class: 'spin')
  rescue Selenium::WebDriver::Error::NoSuchElementError
    true
  end
end
