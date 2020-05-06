# frozen_string_literal: true

class HiCrawler < BaseCrawler
  protected

  def _set_up_page
    @county_table = @driver.find_elements(class: 'col1-b')[0].text
    @hospitalized_table = @driver.find_elements(class: 'col2-b')[0].text
    @driver.find_elements(class: 'more_link')[0].click
    @county_tables = @driver.find_elements(class: 'wp-block-table').map(&:text).select { |t| t =~ /^\w*\sCOUNTY/ }
    @driver.navigate.to 'https://health.hawaii.gov/news/covid-19-updates/'
    url = @driver.page_source.scan(/https:\/\/[^'"]+daily-news-digest-[^'"]+/)[0]
    @driver.navigate.to(url)
    @testing_table = @driver.find_elements(xpath: '//table/tbody').select { |t| t.text =~ /Total Number of Individuals Tested/ }.first
  end

  def _find_hospitalized
    if (deaths = /Required Hospitalization:\n([\d]+)/.match(@hospitalized_table)[1].to_i)
      @results[:hospitalized] = deaths
    end
  end

  def _find_positive
    if @county_table && (total_cases = /Total cases:\n([\d]+)/.match(@county_table)[1].to_i)
      @results[:positive] = total_cases
    end
  end

  def _find_deaths
    if (deaths = /Hawaii deaths:\n([\d]+)/.match(@hospitalized_table)[1].to_i)
      @results[:deaths] = deaths
    end
  end

  def _find_tested
    if @testing_table
      @results[:tested] = @testing_table.text.tr('*','').tr(',','').split("\n")[3].to_i
    elsif @driver.find_elements(class: 'primary-content')[0].text.gsub(',','') =~ /Hawai.?i Totals\s\d+\s\d+\s(\d+)\s(\d+)/
      @results[:tested] = string_to_i($2)
    else
      byebug unless @auto_flag
    end
  end

  def _find_counties
    @results[:counties] = [
      {
        name: "Hawai'i County",
        positive: /Hawai.?i County:\n([\d]+)/.match(@county_table)[1].to_i,
        deaths: @county_tables.select { |t| t =~ /HAWAII COUNTY/ }[0].match(/Deaths (\d+)/)[1].to_i,
      },
      {
        name: "Honolulu County",
        positive: /Honolulu County:\n([\d]+)/.match(@county_table)[1].to_i,
        deaths: @county_tables.select { |t| t =~ /HONOLULU COUNTY/ }[0].match(/Deaths (\d+)/)[1].to_i,
      },
      {
        name: "Kaua'i County",
        positive: /Kaua.?i County:\n([\d]+)/.match(@county_table)[1].to_i,
        deaths: @county_tables.select { |t| t =~ /KAUAI COUNTY/ }[0].match(/Deaths (\d+)/)[1].to_i,
      },
      {
        name: "Maui County",
        positive: /Maui County:\n([\d]+)/.match(@county_table)[1].to_i,
        deaths: @county_tables.select { |t| t =~ /MAUI COUNTY/ }[0].match(/Deaths (\d+)/)[1].to_i,
      },
    ]
  end
end
