# frozen_string_literal: true

class TnCrawler < BaseCrawler

  protected

  def _find_hospitalized
    image = @driver.find_element(xpath: "//img[@title='COVID-19 Cases Hospitalized']")
    return unless image

    image_url = image.attribute('src')
    image_string = RTesseract.new(image_url).to_s.strip.tr("\n", ' ').tr(',', '')
    w = /(\d+)\s*Hospitalized/.match(image_string)
    return unless w

    @results[:hospitalized] = w[1].to_i
  end

  def _find_positive
    image = @driver.find_element(xpath: "//img[@title='Total Cases']")
    return unless image

    image_url = image.attribute('src')
    image_string = RTesseract.new(image_url).to_s.strip.tr("\n", ' ').tr(',', '')
    w = /(\d+)\s*Cases/.match(image_string)
    return unless w

    @results[:positive] = w[1].to_i
  end

  def _find_deaths
    image = @driver.find_element(xpath: "//img[@title='COVID-19 Cases Deaths']")
    return unless image

    image_url = image.attribute('src')
    image_string = RTesseract.new(image_url).to_s.strip.tr("\n", ' ').tr(',', '')
    w = /(\d+)\s*Deaths/.match(image_string)
    return unless w

    @results[:deaths] = w[1].to_i
  end

  def _find_recovered
    image = @driver.find_element(xpath: "//img[@title='COVID-19 Cases Recovered']")
    return unless image

    image_url = image.attribute('src')
    image_string = RTesseract.new(image_url).to_s.strip.tr("\n", ' ').tr(',', '')
    w = /(\d+)\s*Deaths/.match(image_string)
    return unless w

    @results[:recovered] = w[1].to_i
  end

  def _find_tested
    image = @driver.find_element(xpath: "//img[@title='COVID-19 Cases Tested']")
    unless image
      @errors << 'missing image'
      return
    end

    image_url = image.attribute('src')
    image_string = RTesseract.new(image_url).to_s.strip.tr("\n", ' ').tr(',', '')
    w = /(\d+)\s*Tested/.match(image_string)
    unless w
      @errors << 'parse failed for tested'
      return
    end

    @results[:tested] = w[1].to_i
  end
end
