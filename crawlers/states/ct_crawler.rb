# frozen_string_literal: true

class CtCrawler < BaseCrawler
  protected

  def _set_up_page
    url = @driver.find_element(class: 'button--auth').find_element(xpath: ".//a").attribute('href')
    pdf_timestamp = Time.now.strftime('%Y%m%d%H%M')
    `curl #{url} -o data/#{@st}/#{pdf_timestamp}.pdf`
    @reader = PDF::Reader.new("data/#{@st}/#{pdf_timestamp}.pdf")
  end

  def _find_hospitalized
    @results[:hospitalized] = /Patients Currently Hospitalized with COVID-19 (\d+)/.match(page_one)[1]&.to_i
  end

  def _find_positive
    @results[:positive] = /a total of (\d+) cases of COVID-19/.match(page_one)[1]&.to_i
  end

  def _find_deaths
    @results[:deaths] = /COVID-19-Associated Deaths (\d+)/.match(page_one)[1]&.to_i
  end

  def _find_tested
    @results[:tested] = /COVID-19 Tests Reported (\d+)/.match(page_one)[1]&.to_i
  end

  def _find_counties
    page_one.scan(/(\w* \w+ County \d+ \d+)/).flatten.each do |county_data|
      match_data = /\A(.* County) (\d+) (\d+)/.match(county_data)
      @results[:counties] << {
        name: match_data[1]&.strip,
        positive: match_data[2].to_i,
        deaths: match_data[3].to_i,
      }
    end
  end

  def _find_towns
    @results[:towns] = []
    page_five = @reader.page(5).text.gsub(/\s+/,' ').tr(',','')
    page_five.scan(/(Cases)?(\w* ?\w+ \d+)/).each do |_,town|
      if town.include?('not include') || town.include?('Updated')
        next
      end
      town_match = /(.+) (\d+)/.match(town)

      @results[:towns] << {
        name: town_match[1]&.strip,
        positive: town_match[2].to_i,
      }
    end
  end

  def page_one
    @page_one ||= @reader.page(1).text.gsub(/\s+/,' ').tr(',','')
  end
end
