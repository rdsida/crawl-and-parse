# frozen_string_literal: true

class NjCrawler < BaseCrawler
  COUNTY_REGEX = %r((\w+\s*\w*)\s?County:\s(\d+)\sPositive\sTest\sResults\s(\d+)\sDeaths)
  protected

  def _set_up_page
    @page = @driver.find_elements(class: 'card-body').find {|i| i.text=~/Total tests/}.text.gsub(/\s+/, ' ').tr('‡', '')
    @driver.navigate.to('https://covid19.nj.gov')
    @driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    arcgis_url = @driver.find_element(class: 'Dashboard-desktop').attribute('src')
    @driver.navigate.to(arcgis_url)
    ops_url = @driver.find_element(tag_name: 'iframe').attribute('src')
    @driver.navigate.to(ops_url)
    @list_items = @driver.find_elements(class: 'list-item-content')
  end

  def _find_positive
    @results[:positive] = /Positive (\d+)/.match(@page)[1]&.to_i
  end

  def _find_tested
    @results[:tested] = /Total tests (\d+)/.match(@page)[1]&.to_i
  end

  def _find_deaths
    @results[:deaths] = /Deaths (\d+)/.match(@page)[1]&.to_i
  end

  def _find_counties
    @list_items.each do |county|
      county_text = county.text.gsub(/\s+/, " ").tr(',','')
      next unless match_data = COUNTY_REGEX.match(county_text)
      @results[:counties] << {
        name: match_data[1]&.strip,
        positive: match_data[2].to_i,
        deaths: match_data[3].to_i,
      }
    end
  end
end
