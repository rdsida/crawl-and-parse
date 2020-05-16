require 'spec_helper'
require_relative '../../crawlers/base_crawler'

describe BaseCrawler do
  let(:base_crawler) { described_class.new(driver: driver, url: url, st: state ) }

  context 'can be called' do
    let(:driver) { 'mydriver' }
    let(:url) { 'http://dhss.alaska.gov/dph/Epi/id/Pages/COVID-19/monitoring.aspx' }
    let(:state) { 'ak' }
    let(:crawler_errors) { base_crawler.call[:errors][1..-1] }

    it 'not to raise error' do
      expect do
        base_crawler
      end.to_not raise_error
    end

    it 'catch an error' do
      expect(base_crawler.errors).to eq ["crawler failed for ak: #<NoMethodError: undefined method `navigate' for \"mydriver\":String>"]
    end

    it "return the correct result when instantiating" do
      expect(base_crawler.results.to_s).to eq "{:source_urls=>[\"http://dhss.alaska.gov/dph/Epi/id/Pages/COVID-19/monitoring.aspx\"], :counties=>[], :ts=>\"#{Time.now.strftime('%e %b %Y %H:%M:%S%p')}\", :st=>\"ak\"}"
    end

    context 'populate errors' do
      it "with no data tested/negative/positive/deaths" do
        expect(crawler_errors).to eq ["missing tested or negative", "missing positive", "missing deaths"]
      end

      it "with no data tested/negative/positive" do
        base_crawler.results[:deaths] = '2'
        expect(crawler_errors).to eq ["missing tested or negative", "missing positive"]
      end

      it "with no data tested/negative/deaths" do
        base_crawler.results[:positive] = '2'

        expect(crawler_errors).to eq ["missing tested or negative", "missing deaths"]
      end

      it "with no data positive/deaths" do
        base_crawler.results[:tested] = '2'
        base_crawler.results[:negative] = '20'

        expect(crawler_errors).to eq ["missing positive", "missing deaths"]
      end
    end
  end
end
