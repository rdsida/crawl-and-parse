# frozen_string_literal: true

class GaCrawler < BaseCrawler
  protected

  def _set_up_page
    @info_section = @driver.find_elements(id: "KPI1")[1].text.tr(',','').gsub(/\n/, ' ')
    @county_rows = @driver.find_element(tag_name: 'table').find_elements(tag_name: 'tr')
  end

  def _find_positive
    @results[:positive] = /Confirmed COVID-19 Cases\** (\d+)/.match(@info_section)[1]&.to_i
  end

  def _find_tested
    @results[:tested] = /Total Tests\** (\d+)/.match(@info_section)[1]&.to_i
  end

  def _find_deaths
    @results[:deaths] = /Deaths\** (\d+)/.match(@info_section)[1]&.to_i
  end

  def _find_hospitalized
    @results[:hospitalized] = /Hospitalizations\** (\d+)/.match(@info_section)[1]&.to_i
  end


  def _find_counties
    @county_rows.each do |county|
      row_text = county.text
       next if /\ACounty/.match?(row_text) || /\ANon-Georgia Resident/.match?(row_text)
       match_data = /(\D+\s?\D*) (\d+) \d+\.?\d* (\d+) (\d+)/.match(row_text)
       next unless match_data
       @results[:counties] << {
         name: match_data[1],
         positive: match_data[2].to_i,
         deaths: match_data[3].to_i,
         hospitalized: match_data[4].to_i,
       }
    end
  end

end
