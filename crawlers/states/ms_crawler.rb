# frozen_string_literal: true

class MsCrawler < BaseCrawler
  protected

  def _set_up_page
    @county_table_rows = @driver.find_element(id: 'msdhTotalCovid-19Cases').find_elements(tag_name: 'tr')
    @test_table = @driver.find_elements(class: 'simpleTable').find { |t| t.text.match?(/Total tests for COVID-19 statewide/)}
  end

  def _find_positive
    @results[:positive] = /Total (\d+)/.match(@county_table_rows[-1].text.tr(',',''))[1]&.to_i
  end

  def _find_tested
    @results[:tested] = /Total tests for COVID-19 statewide (\d+)/.match(@test_table.text.tr(',',''))[1]&.to_i
  end

  def _find_deaths
    @results[:deaths] = /Total \d+ (\d+)/.match(@county_table_rows[-1].text.tr(',',''))[1]&.to_i
  end


  def _find_counties
    @county_table_rows.each do |county|
      row_text = county.text
       next if /\ACounty/.match?(row_text) || /\ATotal/.match?(row_text)
       match_data = /(\D+\s?\D*) (\d+) (\d+)/.match(row_text)
       next unless match_data
       @results[:counties] << {
         name: match_data[1],
         positive: match_data[2].to_i,
         deaths: match_data[3].to_i,
       }
    end
  end
end
