# frozen_string_literal: true

class NcCrawler < BaseCrawler
  protected

  def _set_up_page
    @table = @driver.find_element(tag_name: 'table').text.tr(',','').gsub(/\s+/, ' ')
    @table_match = /Laboratory-Confirmed Cases Deaths Completed Tests Currently Hospitalized Number of Counties (\d+) (\d+) (\d+) (\d+) \d+/.match(@table)
  end

  def _find_positive
    @results[:positive] = @table_match[1]&.to_i
  end

  def _find_tested
    @results[:tested] = @table_match[3]&.to_i
  end

  def _find_deaths
    @results[:deaths] = @table_match[2]&.to_i
  end

  def _find_hospitalized
    @results[:hospitalized] = @table_match[4]&.to_i
  end
end
