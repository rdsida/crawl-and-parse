# frozen_string_literal: true

require_relative 'base_crawler'

class AkCrawler < BaseCrawler

  protected

  def _set_up_page
    url = @driver.page_source.scan(/https[^'"]+arcgis\.com\/apps\/opsdashboard[^'"]+/)[0]
    @driver.navigate.to(url)
  end

  def _find_positive
    w = /Total Cases(\d+)/.match(_page_elements)
    return unless w

    @results[:positive] = w[1].to_i 
  end

  def _find_tested
    # NOTE: I've been unsuccessfully digging into the "Combined Cumulated" graph,
    # looking for the aria-label value of the last <circle>

    #graph_next_arrow = @driver.find_element(xpath: '//a[@data-ember-action-415="415"]')
    #return unless graph_next_arrow

    #w = nil
    #return unless w

    #@results[:tested] = w[1].to_i 
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
    @_page_elements ||= wait.until {
      @driver.find_element(class: 'claro')
    }.text.tr("\n", '')
  end
end
