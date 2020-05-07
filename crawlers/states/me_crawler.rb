# frozen_string_literal: true

# Parse Maine
# https://www.maine.gov/dhhs/mecdc/infectious-disease/epi/airborne/coronavirus.shtml
class MeCrawler < BaseCrawler
  protected

  def _set_up_page
    wait.until { @driver.find_element(class: 'travelAdvisories') }
  end

  def _find_positive
    @results[:positive] = read_cell 0
    puts @results[:positive]
  end

  # if :tested is not available, find :negative
  def _find_tested
    @results[:negative] = string_to_i(
      document.at_css('span.d').child.to_s
    )
  end

  def _find_deaths
    @results[:deaths] = read_cell 5
  end

  def _find_recovered
    @results[:recovered] = read_cell 3
  end

  def _find_hospitalized
    @results[:hospitalized] = read_cell 4
  end

  # _find_counties

  # _find_towns

  private

  # Pull an integer out of the indicated 'Cumulative Case Data' table, by column
  # number, zero-indexed. This row alternates text and td elements, requiring a
  # little math to get the right cell.
  def read_cell(column)
    string_to_i(data_row[column * 2 + 1].child.to_s)
  end

  def document
    @document ||= Nokogiri::HTML.parse(@driver.page_source)
  end

  # Fish out a table row which contains some information we're interested in.
  def data_row
    @data_row ||= document.css('table.travelAdvisories tr')[3]
                          .children
  end
end
