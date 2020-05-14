# frozen_string_literal: true

class OrCrawler < BaseCrawler
  protected

  def _set_up_page
    @driver.find_element(class: 'prefix-overlay-close')&.click
    @cases_table = @driver.find_element(id: 'collapseCases').find_element(tag_name: 'table').text.gsub(/\s+/, ' ').tr(',','')
    @driver.find_element(id: 'headingDemographics').find_element(tag_name: 'button').click
    @county_rows = @driver.find_element(id: 'collapseDemographics').find_element(tag_name: 'tbody').find_elements(tag_name: 'tr')
  end

  def _find_positive
    @results[:positive] = /Total cases (\d+)/.match(@cases_table)[1].to_i
  end

  def _find_tested
    @results[:tested] = /Total tested (\d+)/.match(@cases_table)[1].to_i
  end

  def _find_deaths
    @results[:deaths] = /Total deaths (\d+)/.match(@cases_table)[1].to_i
  end

  def _find_counties
    @county_rows.each do |county|
      county_text = county.text.gsub(/\s+/, " ").tr(',','')
      unless !(/Total \d+ \d+ \d+/.match?(county_text)) && match_data = /(\w+\s*\w*) (\d+) (\d+) (\d+)/.match(county_text)
        next
      end

      @results[:counties] << {
        name: match_data[1]&.strip,
        positive: match_data[2].to_i,
        deaths: match_data[3].to_i,
        negatives: match_data[4].to_i,
      }
    end
  end
end
