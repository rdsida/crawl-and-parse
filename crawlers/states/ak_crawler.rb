# frozen_string_literal: true

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
    sec = 4
    loop do # open the cumulative tests by day graph
      @_page_elements = nil
      if /Cumulative Tests by Day \(Combined\)/.match(_page_elements)
        @driver.find_element(id: "ember121").find_elements(tag_name: "circle").last.attribute("aria-label") =~ /([^\s]+)$/
        @results[:tested] = string_to_i  $1
        break
      else
        @driver.find_element(id: "ember413").click
        sec -= 1
        sleep 1
        puts "#{sec} seconds remaining"
      end
      break if sec == 0
    end
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
