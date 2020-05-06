require 'spec_helper'
require 'selenium-webdriver'
require_relative '../crawlers/base_crawler'

describe BaseCrawler do
  let(:base_crawler) { described_class.new(driver: driver, url: url, st: state ) }

  context 'with uncorrect argument' do
    let(:driver) { 'mydriver' }
    let(:url) { 'wrong url' }
    let(:state) { 'state' }

    it 'not to raise error' do
      expect do
        base_crawler
      end.to_not raise_error
    end

    it 'rescue an error' do
      expect(base_crawler.errors).to eq ["crawler failed for state: #<NoMethodError: undefined method `navigate' for \"mydriver\":String>"]
    end
  end

  context 'with correct arguments' do
    let(:driver) { Selenium::WebDriver.for :firefox }
    let(:url) { 'http://dhss.alaska.gov/dph/Epi/id/Pages/COVID-19/monitoring.aspx' }
    let(:state) { 'ak' }

    it "return the correct result when instantiating" do
      expect(base_crawler.results.to_s).to eq "{:source_urls=>[\"http://dhss.alaska.gov/dph/Epi/id/Pages/COVID-19/monitoring.aspx\"], :counties=>[], :ts=>\"#{Time.now.strftime('%e %b %Y %H:%M:%S%p')}\", :st=>\"ak\"}"
    end
  end
end
