# frozen_string_literal: true

class BaseCrawler
  def initialize(driver:, url: @url)
    @driver = driver
    @url = url
    @driver.navigate.to(@url)
    @results = {
      source_urls: [@url],
      counties: [],
      ts: Time.now
    }
  end
end
