# frozen_string_literal: true

require './crawlers/base_crawler.rb'

class TnCrawler < BaseCrawler
  def call
    _find_positive
    _find_tested
    _find_deaths
    _find_recovered
    _find_hospitalized

    @results
  end

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
    return unless image

    image_url = image.attribute('src')
    image_string = RTesseract.new(image_url).to_s.strip.tr("\n", ' ').tr(',', '')
    w = /(\d+)\s*Tested/.match(image_string)
    return unless w

    @results[:tested] = w[1].to_i
  end
end
