# frozen_string_literal: true

require_relative 'base_crawler'

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
    w = /CONFIRMED CASES(\d+(,\d+)*)?/.match(_page_elements)
    return unless w
    @results[:positive] = w[1].tr(',', '').to_i
  end

  def _find_tested
    w = /TOTAL TESTED(\d+(,\d+)*)?/.match(_page_elements)
    return unless w
    @results[:tested] = w[1].tr(',', '').to_i
  end

  def _find_deaths
    w = /DEATHS(\d+(,\d+)*)?/.match(_page_elements)
    return unless w
    @results[:deaths] = w[1].tr(',', '').to_i
  end

  def _find_hospitalized
    w = /TOTAL HOSPITALIZATIONSSINCE \d+\/\d+\/\d{4}(\d+(,\d+)*)?/.match(_page_elements)
    return unless w
    @results[:hospitalized] = w[1].tr(',', '').to_i
  end

  private

  def _page_elements
    @_page_elements ||= wait.until {
      @driver.find_element(class: 'dashboard-page')
    }.text.tr("\n", '')
  end
end

