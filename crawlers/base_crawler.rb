# frozen_string_literal: true

require 'byebug'
require 'nokogiri'
require 'selenium-webdriver'
require 'pdf-reader'
require 'humanize'
require 'rtesseract'

# Holds functionality common to all crawlers
class BaseCrawler
  attr_accessor :errors, :results
  include Utils
  def initialize(driver:, url: @url, st: @st)
    @driver     = driver
    @url        = url
    @st         = st
    @path       = 'data/'
    @filetime   = Time.now.to_s[0..18].gsub(' ', '-').gsub(':', '.')
    @page_count = 0
    @errors = []
    begin
      @driver.navigate.to(@url)
      open("#{@path}#{@st}/#{@filetime}_#{@page_count+=1}", 'w') do |f|
        f.puts url
        f.puts @driver.page_source
      end
    rescue StandardError => e
      @errors << "crawler failed for #{@st}: #{e.inspect}"
    end

    @results = results_init
  end

  # This needed to be extracted to its own method, because the old monolithic
  # crawler inherits from this class but overrides the initialize method.
  # Once all crawlers are extracted into their own classes, we can put it back.
  def results_init
    {
      source_urls: [@url],
      counties: [],
      ts: Time.now,
      st: @st
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
    _find_towns

    @results
  end

  def wait
    Selenium::WebDriver::Wait.new(timeout: 60)
  end

  def crawl_page(url = @url)
    @results[:source_urls] << url
    begin
      @driver.navigate.to(url)
      open("#{@path}#{@st}/#{@filetime}_#{@page_count+=1}", 'w') do |f|
        f.puts url
        f.puts @driver.page_source
      end
    rescue
      @errors << "crawler failed for #{@st}: #{e.inspect}"
    end
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

  def _find_towns
  end
end
