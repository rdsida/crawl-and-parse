# frozen_string_literal: true

class WaCrawler < BaseCrawler
  protected

  def _set_up_page
    sleep(5)
    @driver.find_element(id: 'togConfirmedCasesDeathsTbl').click
    @driver.find_element(id: 'togTestingTbl').click
    @driver.find_element(id: 'togHospAndIcuTbl').click

    @county_table = @driver.find_element(id: 'pnlConfirmedCasesDeathsTbl')
    @testing_table = @driver.find_element(id: 'pnlTestingTbl').text.tr(',','')
    @hospitalized_table = @driver.find_element(id: 'pnlHospAndIcuTbl')
  end

  def _find_hospitalized
    if @hospitalized_table && (hospitalized = @hospitalized_table.find_elements(tag_name: 'tr')[-1].text.split(" ")[2].to_i)
      @results[:hospitalized]
    end
  end

  # def _find_positive
  #   if @county_table && (total_cases = /Total (\d+) \d+/.match(@county_table.tr(",", ""))[1].to_i)
  #     @results[:positive] = total_cases
  #   end
  # end

  def _find_deaths
    if @county_table && (deaths = /Total \d+ (\d+)/.match(@county_table.find_elements(tag_name: 'tr')[-1].text.tr(",", ""))[1].to_i)
      @results[:deaths] = deaths
    end
  end

  def _find_tested
    if @testing_table
      @results[:positive] = /Positive (\d+)/.match(@testing_table)[1].to_i
      @results[:negative] = /Negative (\d+)/.match(@testing_table)[1].to_i
      # doesn't currently report/display pending tests
      @results[:pending] = 0
      @results[:tested] = @results[:positive] + @results[:negative]
    end
  end

  def _find_counties
    if @county_table
      @county_table.find_elements(tag_name: 'tr').each do |county|
        data = county.text.split
        next if %w(Total County).include?(data[0])
        @results[:counties] << {
          name: data[0],
          positive: data[1].tr(",","").to_i,
          deaths: data[2].tr(",","").to_i,
        }
      end
    end
  end
end
