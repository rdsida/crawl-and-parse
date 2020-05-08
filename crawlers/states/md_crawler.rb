# frozen_string_literal: true

class MdCrawler < BaseCrawler
  protected

  def _set_up_page
    wait.until do
      @driver.find_element(xpath: '//div[contains(@style, "#1c1b1a")]')
             .text
             .match(/Number of confirmed cases/)
    end
  end

  def _find_positive
    @results[:positive] = /Number of confirmed cases  (\d+)/.match(page_elements)[1]&.to_i
  end

  def _find_tested
    @results[:negative] = /Number of negative test results  (\d+)/.match(page_elements)[1]&.to_i
  end

  def _find_deaths
    @results[:deaths] = /Number of confirmed deaths  (\d+)/.match(page_elements)[1]&.to_i
  end

  def _find_hospitalized
    @results[:hospitalized] = /Currently hospitalized  (\d+)/.match(page_elements)[1]&.to_i
  end

  def _find_counties
    counties.map do |county|
      @results[:counties] << [:name, :positive].zip(county).to_h
    end
  end

  private

  def page_elements
    @page_elements ||=
      @driver.find_element(xpath: '//div[contains(@style, "#1c1b1a")]')
             .text
             .delete("\n,:")
  end

  def counties_elements
    @counties_elements ||= @page_elements.scan(/Allegany.*By Age/)    
                                         .first
                                         .delete("()")
  end

  def counties
    # Regex may be improved to avoid catching "*"
    counties_elements.scan(/(\D+\D?) (\d+)/)
                     .each { |c| c.first.delete!("*") }
  end
end
