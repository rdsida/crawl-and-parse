# frozen_string_literal: true

class BaseCrawler
  def initialize(driver:, url: @url, st: @st)
    @driver = driver
    @url = url
    @st = st
    @driver.navigate.to(@url)
    @results = {
      source_urls: [@url],
      counties: [],
      ts: Time.now,
      st: st
    }
  end

  def call
    _set_up_page
    _find_positive
    _find_tested
    _find_deaths
    _find_recovered
    _find_hospitalized
    _find_counties
    @results
  end

  def wait
    Selenium::WebDriver::Wait.new(timeout: 60)
  end 

  def crawl_page(url)
    @results[:source_urls] << url
    @driver.navigate.to(url)
    
  end

  protected

  def _set_up_page
  end

  def _find_positive
  end

  def _find_tested
    # if :tested is not available, find :negative
  end

  def _find_deaths
  end

  def _find_recovered
  end

  def _find_hospitalized
  end

  def _find_counties
  end

end
