# frozen_string_literal: true

class MiCrawler < BaseCrawler
  protected

  # _set_up_page

  def _find_positive
    if (@s = @driver.find_elements(id: 'main')[0].text).gsub(',','') =~ /Total Confirmed Cases\n(\d+)\nTotal COVID-19 Deaths\n(\d+)\n/
      @results[:positive] = $1.to_i
      @results[:deaths] = $2.to_i      
    else
      @errors << 'missing cases and deaths'
    end
  end

  def _find_tested
    x = @driver.find_elements(class: 'moreLink').select {|i| i.text =~ /Cumulative Data/i}.first
    x.click
    sleep 2
    unless @driver.page_source =~ /<a href\="([^"]+)">Lab Testing/
      @errors << 'missing tested'
      return
    end
    url = 'https://www.michigan.gov' + $1
    crawl_page url
    cols = @driver.find_elements(class: 'fullContent')[0].text.split("\n").map {|i| i.strip}
    i = 2 
    tested = 0
    loop do
      temp = cols[i+=1].split("\s")
      date = temp[0]
      break unless date =~ /2020/
      tested += temp[-2].gsub(',','').to_i
    end
    @results[:tested] = tested
  end

  # _find_deaths

  # _find_recovered

  # _find_hospitalized

  # _find_counties

  # _find_towns
end

