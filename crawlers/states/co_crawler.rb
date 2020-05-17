# frozen_string_literal: true

class CoCrawler < BaseCrawler

  protected

  def _find_positive
    w = /((\d+,)*\d+)Cases/.match(_page_elements)
    return unless w
    @results[:positive] = w[1].tr(',', '').to_i
  end

  def _find_tested
    w = /((\d+,)*\d+)People tested/.match(_page_elements)
    return unless w
    @results[:tested] = w[1].tr(',', '').to_i
  end

  def _find_deaths
    w = /((\d+,)*\d+)deaths among cases/.match(_page_elements)
    return unless w
    @results[:deaths] = w[1].tr(',', '').to_i
  end

  def _find_hospitalized
    w = /((\d+,)*\d+)Hospitalized/.match(_page_elements)
    return unless w
    @results[:hospitalized] = w[1].tr(',', '').to_i
  end

  private

  def _page_elements
    @_page_elements ||= wait.until {
      @driver.find_element(class: 'paragraph__column')
    }.text.tr("\n", '')
  end
end

