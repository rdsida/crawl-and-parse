require 'byebug'
require 'nokogiri'
require 'selenium-webdriver'
require 'pdf-reader'
require 'humanize'

# not automatic:
# ['ak', "az", 'id', 'ks', 'mi', 'oh', "nd", 'ny', 'tn', 'wy']
# ak have images
# with tableau iframe (ocr needed): az ca va ia ks ny wy
# with pdfs: ct

# counties with death done: mi, wa, pa
# counties done without death: ny, nj, ma, ct(towns)broken

# counties available: de, ia

# missing counties: ca
# missing tested:   de, ms, oh, me (neg)
# missing deaths:   

SEC = 30 # seconds to wait for page to load
OFFSET = nil # if set, start running at that state
SKIP_LIST = [] # skip these states

=begin

Structure of the hash h, where STATE crawl data is stored

h = {
	:ts => Time.now, # timestamp of crawl
	:st => @st, # 2 letter STATE abbreviation
	:source_urls => [@url], # array of urls crawled
	:source_texts => [], # array of source text crawled
	:source_files => [], # array of filenames of pdfs or other files saved
	:tested => int,
	:positive => int,
	:negative => int,
	:pending => int,
	:deaths => int,
	:hospitalized => int,
	:recovered => int,
	:ts_tested => string, # update time of the specific data listed on the website
	:ts_positive => string,
	:ts_negative => string,
	:ts_pending => string,
	:ts_... # update time of other future fields
	:counties => [ { :name => string, 
	                 :tested => int, 
	                 :positive => int,
	                 :negative => int,
	                 :deaths => int }, ... ] # array of county specific fields, note that ts is for whole county
	:ts_counties => string
}

=end

class Crawler

  # parse_XXX methods for the 50 US states and DC

  def parse_ak(h)
    crawl_page
    url = @driver.page_source.scan(/https[^'"]+arcgis\.com\/apps\/opsdashboard[^'"]+/)[0]
    crawl_page url
    sec = SEC/6
    loop do
      @s = @driver.find_element(class: 'claro').text.gsub(',','')
      if @s =~ /\nTotal Cases\n(\d+)\n/
        h[:positive] = $1.to_i
        if @s =~ /\nDeaths\n(\d+)\n/
          h[:deaths] = $1.to_i
          break
        end
      end
      sec -= 1
      if sec == 0
        @errors << 'parse failed'
        return h
      end
      puts "sleeping: #{sec}"
      sleep 1
    end

    puts 'AK: tested data in image?'
    if @auto_flag
      @warnings << 'tested was not manually entered'
    else
      byebug 
    end
    # Cumulative number of cases hospitalized to date:  0
    # positive by region available
    # TODO TESTED manual
    h
  end

  def parse_al(h)
    crawl_page
    url = @s.scan( /[^'"]+alpublichealth.maps.arcgis.com[^'"]+/ )[0]
    raise unless url
    crawl_page url
    sec = SEC/3
    loop do
      t = @driver.find_elements(class: 'dashboard-page')[0]
      (s=t.text.gsub(',','')) if t
      if t && s =~ /CONFIRMED CASES\n(\d+)\nTOTAL TESTED\n(\d+)\nCOVID-19 DEATHS\n(\d+)\n/
        h[:tested] = string_to_i($2)
    	h[:deaths] = string_to_i($3) # switched
        h[:positive] = string_to_i($1)
        @s += "\nBREAK\n" + s
        break
      end
      sec -= 1
      if sec == 0
        @errors << 'parse failed'
        break
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
    # counties available
    h
  end

  def parse_ar(h)
    crawl_page
    @url = @driver.page_source.scan(/http[^'"]+maps\.arcgis\.com[^'"]+/)[0]
    unless @url
      @errors << 'url missing'
      return h
    end
    crawl_page
    sec = SEC
    loop do
      flag = false
      @s = @driver.find_elements(class: 'dashboard-page')[0].text
      t = @s.scan(/Arkansas Totals\nCumulative Cases\n([^\n]+)\n/)
      if t.size > 0
        h[:positive] = string_to_i(t[0][0])
      else
        flag = true
      end
      t = @s.scan(/\nTotal Tested for COVID-19\n([^\n]+)/)
      if t.size > 0
        h[:tested] = string_to_i(t[0][0])
      else
        flag = true
      end 
      t = @s.scan(/\nDeaths\n([^\n]+)/)
      if t.size == 2
        h[:deaths] = string_to_i(t[0][0])
      else
        flag = true
      end
      if flag
        puts "sleeping...#{sec}"
        sec -= 1
        sleep 1
        if sec == 0
          @errors << 'parse failed'
          return h
        end
      else
        break 
      end
    end
    h
  end

  def parse_az(h)
    if @auto_flag
      puts "skipping AZ"
      h[:skip] = true
      return h
    end

    #unless @auto_flag
if true
      @url = 'https://www.azdhs.gov/preparedness/epidemiology-disease-control/infectious-disease-epidemiology/index.php#novel-coronavirus-home'
      crawl_page
      url = @driver.page_source.scan(/https:\/\/tableau\.azdhs\.gov[^'"]+/).select {|i| i=~/dashboard/i}[0]
      sleep 4
      crawl_page url
      sleep 3
      @driver.find_elements(class: 'tabCanvas')[3].click
      @driver.find_elements(class: 'tabToolbarButton').select {|i| i.text =~ /Download/}[0].click
      x = @driver.find_elements(class: "tab-downloadDialog")[0]
      x.find_elements(:css, "*")[4].click
      x = @driver.find_elements(class: "tab-pdf-dialog-buttons")[0]
sleep 3
      x.find_elements(:css, "*")[1].click
      `rm "/Users/danny/Downloads/Story 1.pdf"`
      sleep 3
      @driver.find_elements(class: "tabDownloadFileButton")[0].click
      sleep 2
      #reader = PDF::Reader.new("/Users/danny/Downloads/Story 1.pdf")
      #result = reader.page(1).text.gsub(/\s+/,' ').gsub(',','')
open("/Users/danny/Downloads/Story 1.pdf")
`mv "/Users/danny/Downloads/Story 1.pdf"  #{@path}#{@st}/#{@filetime}_1.pdf`
puts 'manual entry'


byebug unless @auto_flag
      return h
    end

    # TODO use https://www.azdhs.gov/preparedness/epidemiology-disease-control/infectious-disease-epidemiology/index.php#novel-coronavirus-home
=begin
    @driver.navigate.to(@url) 
    unless @url = @driver.page_source.scan(/http[^'"]+tableau\.azdhs\.gov\/views[^'"]+/)[0]
      @errors << 'missing url'
      return h
    end
=end
    crawl_page
    `rm /Users/danny/Downloads/Cases_crosstab.csv`
    `rm /Users/danny/Downloads/Testing_crosstab.csv`
    sleep(3)
    @driver.find_elements(class: "tabCanvas")[0].click
    @driver.find_elements(class: "download")[0].click
    x = @driver.find_elements(class: "tab-downloadDialog")[0]
    
#x.find_elements(:css, "*")[4].click
#byebug
#@driver.find_elements(class: "tab-pdf-dialog-buttons")[0].click

    x.find_elements(:css, "*")[3].click
    @driver.find_elements(class: "tabDownloadFileButton")[0].click
    byebug # manually save, required to set browser preferences
    @driver.find_elements(class: "tabCanvas")[9].click
    @driver.find_elements(class: "download")[0].click
    x = @driver.find_elements(class: "tab-downloadDialog")[0]
    x.find_elements(:css, "*")[3].click
    @driver.find_elements(class: "tabDownloadFileButton")[0].click
    sleep(2)
    `dos2unix /Users/danny/Downloads/Cases_crosstab.csv`
    `dos2unix /Users/danny/Downloads/Testing_crosstab.csv`
    rows = open('/Users/danny/Downloads/Testing_crosstab.csv').readlines.map {|i| i.strip.split("\t")}
    if i = rows.select {|i| i[0] =~ /Number of People Tested/}.first
      h[:tested] = string_to_i(i[1])
    else
      @errors << "missing tested"
    end
    if i = rows.select {|i| i[0] =~ /Number of Positive/}.first
      h[:positive] = string_to_i(i[1])
    else
      @errors << "missing positive"
    end
    if i = rows.select {|i| i[0] =~ /Number of Pending/}.first
      h[:pending] = string_to_i(i[1])
    else
      @errors << "missing pending"
    end
    if i = rows.select {|i| i[0] =~ /Number of Ruled-Out/}.first
      h[:negative] = string_to_i(i[1])
    else
      @errors << "missing negative"
    end
    rows = open('/Users/danny/Downloads/Cases_crosstab.csv').readlines.map {|i| i.strip.split("\t")}
    if i = rows.select {|i| i[0] =~ /Total Cases/}.first
      #byebug if string_to_i(i[1]) != h[:positive]
      h[:positive] = string_to_i(i[1])
    else
      @errors << "missing total cases"
    end
    if i = rows.select {|i| i[0] =~ /Total Deaths/}.first
      h[:deaths] = string_to_i(i[1])
    else
      @errors << "missing deaths"
    end
    if i = rows.select {|i| i[0] =~ /^Private Laboratory/}.first
      h[:tested] = 0 unless h[:tested]
      h[:tested] += string_to_i(i[1])
    else
      @errors << "missing private library tests"
    end
    `mv /Users/danny/Downloads/Testing_crosstab.csv #{@path}az/#{Time.now.to_s[0..18].gsub(' ','_')}_Testing_crosstab.csv`
    `mv /Users/danny/Downloads/Cases_crosstab.csv #{@path}az/#{Time.now.to_s[0..18].gsub(' ','_')}_Cases_crosstab.csv`

      @url = 'https://www.azdhs.gov/preparedness/epidemiology-disease-control/infectious-disease-epidemiology/index.php#novel-coronavirus-home'
      crawl_page
      url = @driver.page_source.scan(/https:\/\/tableau\.azdhs\.gov[^'"]+/).select {|i| i=~/dashboard/i}[0]
      crawl_page url
puts "manual tested:"
byebug


    h
  end

  def parse_ca(h)
    crawl_page
    sec = SEC/5
    loop do
      @s = @driver.find_elements(id: 's4-workspace').first.text.gsub(/\s+/,' ')
      if @s =~ /there are a total of (.*) positive cases and (.*) deaths /
        h[:positive] = string_to_i($1)
        h[:deaths] = string_to_i($2)
        break
      elsif sec == 0
        @errors << 'CA parse failed'
        break
      end
      sec -= 1
      puts "sleeping...#{sec}"
      sleep 1
    end
    url = 'https://www.cdph.ca.gov/Programs/OPA/Pages/New-Release-2020.aspx'
    crawl_page url
    urls = @driver.page_source.scan(/Programs\/OPA\/Pages\/NR[^"']+/).map {|i| 'https://www.cdph.ca.gov/' + i}.sort.reverse # NR20-32.aspx
    url = urls.shift
    while url =~ /NR20-32.aspx/
      url = urls.shift
    end
    # Negative from CDPH report of 778 tests on 3/7, and 88 pos => 690 neg
    crawl_page url
    if (x=@driver.find_element(id: 'MainContent')) && x.text =~ /pproximately ([0-9,]+)([\+\*]+)? tests had been conducted in California/
      h[:tested] = string_to_i($1)
    else
      byebug unless @auto_flag
      @errors << 'missing tested'
    end
    # TODO source is 2 urls
    h
  end

  def parse_co(h)
    crawl_page

    s = @driver.find_elements(class: 'paragraph__column').map {|i| i.text.gsub(',','')}.select {|i| i=~/People tested/}[0]
    if s && s =~ /(\d+)\sCases/
      h[:positive] = string_to_i($1)
      if s && s =~ /(\d+)\sPeople tested/
        h[:tested] = string_to_i($1)
        if s && s =~ /\n(\d+)\*\nDeaths\n/
          h[:deaths] = string_to_i($1)
        else
          @errors << 'missing deaths'
        end
      else
        @errors << 'missing tested'
      end
    else
      @errors << "parse failed"
    end
    # counties available
    h
  end

  # TODO death number is words
  def parse_ct(h)
    crawl_page
    if @s =~ /([^'"]+CTDPHCOVID19summary[^'"]+)/
      url = 'https://portal.ct.gov' + $1
      `curl #{url} -o #{@path}#{@st}/#{@filetime}_1.pdf`
      `open #{@path}#{@st}/#{@filetime}_1.pdf` unless @auto_flag
      reader = PDF::Reader.new("#{@path}#{@st}/#{@filetime}_1.pdf")
      result = reader.page(1).text.gsub(/\s+/,' ').gsub(',','')
      if result =~ /a total of ([\d]+) laboratory-confirmed cases of COVID-19 have been reported/
        h[:positive] = string_to_i($1)
      else
        @errors << 'missing positive'
      end
      if result =~ /been ([^\s]+) laboratory-confirmed COVID-19-associated death/
        h[:deaths] = string_to_i($1.strip)
      else
        @errors << 'missing deaths'
      end
      #result = reader.page(7).text.gsub(/\s+/,' ').gsub(',','') 
      if result =~ /Patients tested for COVID-19 (\d+) /
        h[:tested] = string_to_i($1)
      else
        byebug unless @auto_flag
        @errors << 'missing tested'
      end
      # towns, not counties
=begin
      h[:towns] = []
      rows = reader.page(5).text.gsub(',','').split("\n")
      for r in rows
        if r =~ /^([A-Z].*[a-z])\s+(\d+)\s+([A-Z].*[a-z])\s+(\d+)\s+([A-Z].*[a-z])\s+(\d+)$/
          h_town = {}
          h_town[:name] = $1
          h_town[:positive] = $2.to_i
          h[:towns] << h_town
          h_town[:name] = $3
          h_town[:positive] = $4.to_i
          h[:towns] << h_town
          h_town[:name] = $5
          h_town[:positive] = $6.to_i
          h[:towns] << h_town
        elsif r =~ /^([A-Z].*[a-z])\s+(\d+)\s+([A-Z].*[a-z])\s+(\d+)$/
          h_town = {}
          h_town[:name] = $1
          h_town[:positive] = $2.to_i
          h[:towns] << h_town
          h_town[:name] = $3
          h_town[:positive] = $4.to_i
          h[:towns] << h_town
        end
      end
      if h[:towns].size < 169
        @errors << 'missing towns'
      end
=end
    else
      @errors << 'missing pdf'
    end
    h
  end

  def parse_dc(h)
    # TODO count calc may be off
    crawl_page
    @s = @driver.find_elements(id: 'page').first.text.gsub(',','').gsub(/\s+/,' ')
    if (x = @s.scan(/Total Positives:\s?([0-9]+)[^0-9]/)).size > 0
      h[:positive] = x.map {|i| string_to_i(i.first)}.max
    else
      @errors << "positive missing"
    end
    if (x = @s.scan(/Total Tested Overall:\s?([0-9]+)[^0-9]/)).size > 0
      h[:tested] = x.map {|i| string_to_i(i.first)}.max
    else
      @errors << "tested missing"
    end
    if (x = @s.scan(/Total Deaths:\s?([0-9]+)[^0-9]/)).size > 0
      h[:deaths] = string_to_i(x[0][0])
    end
    if (x = @s.scan(/Total Lives Lost:\s?([0-9]+)[^0-9]/)).size > 0
      x = string_to_i(x[0][0])
      h[:deaths] = x if !h[:deaths] || x > h[:deaths]
    end
    unless h[:deaths]
      @errors << "deaths missing"
    end
    h
  end

  def parse_de(h)
    crawl_page
    if url = @s.scan(/https:\/\/dshs.maps\.arcgis\.com\/apps\/opsdashboard\/index\.htm[^'"]+/).first
      crawl_page url
    else
      @errors << 'dashboard url not found'
      return h
    end
    sec = SEC/4
    loop do
      @s = @driver.find_elements(class: 'dashboard-page')[0].text.gsub(',','')
      if @s =~ /Positive Cases\n(\d+)/
        h[:positive] = string_to_i($1)
        if @s =~ /Total Deaths\n(\d+)\n/
          h[:deaths] = string_to_i($1)
          if @s =~ /Negative Cases\n(\d+)/
            h[:negative] = string_to_i($1)
            break
          end
        end
      end
      sec -= 1
      if sec == 0
        @errors << 'parse failed'
        return h
      end
      puts "sleeping... #{sec}"
      sec -= 1
      sleep 1
    end
    # https://news.delaware.gov/2020/03/29/public-health-announces-1-additional-death-18-additional-positive-cases-in-delaware/
    # TODO tested, not available
    # https://news.delaware.gov/2020/03/31/covid-19-in-delaware-public-health-announces-3-additional-deaths-55-more-positive-cases-in-delaware/
    # TODO counties
    h
  end

  def parse_fl(h)
    crawl_page
    sec = SEC/5
    loop do
     stats = {tested: "tested-total-stat", positive: "total-cases-stat", deaths: "deaths-stat"}
     stats.each do |k, v|
        begin
          h[k] = @driver.find_element(id: v).text.gsub(",", "").to_i
          puts k.to_s
          puts h[k]
        rescue
          @errors << "#{k.to_s} missing"
          byebug unless @auto_flag
        end
      end
     break if stats.map{|k, v| h[k]}.all?{|i| i.class == Integer && i > 0} # break loop if all stats are present
      if sec == 0
        @errors << 'parse failed'
        break
      end
      sec -= 1
      puts "sleeping...#{sec}"
      sleep 1
    end # loop
    # if @driver.page_source =~ /"([^"]+)arcgis\.com([^"]+)"/
    #   url = $1 + 'arcgis.com' + $2
    #   crawl_page url
    #   sec = SEC/8
    #   url = nil
    #   loop do
    #     if @driver.page_source =~ /https:\/\/arcg.is([^"]+)"/
    #       url = 'https://arcg.is' + $1
    #       break
    #     else
    #       sec -= 1
    #       puts "sleeping1...#{sec}"
    #       sleep 1
    #       if sec == 0
    #         @errors << '2nd dash link not found'
    #         break
    #       end
    #     end
    #   end
    #   if url
    #     crawl_page url
    #     sec = SEC/8
    #     loop do
    #       begin
    #         @driver.find_elements(class: 'tab-title').select {|i| i.text =~ /Testing/}[0].click
    #         s = @driver.find_elements(class: 'dashboard-page')[0].text
    #         if s =~ /\nTotal Tests\n([^\n]+)\n/
    #           h[:tested] = string_to_i($1)
    #           if s.gsub(',','') =~ /\nTotal Cases\s(\d+)/
    #             h[:positive] = string_to_i($1)
    #             if s.gsub(',','') =~ /\nDeaths\s(\d+)/
    #               h[:deaths] = string_to_i($1)
    #               @s += "\nBREAK\n" + s
    #               break
    #             end
    #           end
    #         end
    #       rescue
    #       end
    #       if sec == 0
    #         @errors << 'parse failed'
    #         break
    #       end
    #       sec -= 1
    #       puts "sleeping2...#{sec}"
    #       sleep 1
    #     end
    #   end
    # else
    #   @errors << 'dashboard not found'
    # end
    h
  end

  def parse_ga(h)
    crawl_page
    unless url = @driver.page_source.scan(/https:\/\/[^'"]+\.cloudfront\.net[^'"]+/).first
      @errors << 'missing url'
      return h
    end
    crawl_page url
    @s = @driver.find_element(class: 'not-embedded').text.gsub(',','')
    if x = @s.scan(/No. Cases \(\%\)\nTotal ([0-9]+)/).first
      h[:positive] = string_to_i(x[0])
    else
      @errors << 'missing positive'
    end
    if x = @s.scan(/Deaths ([0-9]+)/).first
      h[:deaths] = string_to_i(x[0])
    else
      @errors << 'missing deaths'
    end
    if x = @s.scan(/Total Tests\nCommercial Lab [0-9]+ ([0-9]+)\nGphl [0-9]+ ([0-9]+)/).first
      h[:tested] = string_to_i(x[0]) + string_to_i(x[1])
    else
      @errors << 'missing tested'
    end
    cols = @s.split("\n")
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/COVID-19 Confirmed Cases By County: No. Cases No. Deaths/}.first
      i = x[1]+1
      h[:counties] = []
      while !(cols[i] =~ /^Unknown/) && cols[i] =~ /^(.*) ([\d]+) ([\d]+)$/
        h_county = {}
        h_county[:name] = $1.strip
        h_county[:positive] = string_to_i($2)
        h_county[:deaths] = string_to_i($3)
        h[:counties] << h_county
        i += 1
      end
    else
      @errors << 'missing counties'
    end
    h
  end

  def parse_hi(h)
    crawl_page
    s = @driver.find_element(id: 'main').text.gsub(',','')
    @s += "\nBREAK\n" + s
    tables = @driver.find_elements(class: 'data_list').map {|i| i.text.gsub(',','')}
    if t=s.scan(/Total \(new\):\s([\d]+)/).first
      h[:positive] = string_to_i(t[0]) 
    elsif (t=tables.select {|i| i=~/Total cases/}.first) && t =~ /Total cases:\n([\d]+)/
      h[:positive] = string_to_i($1)
    else
      @errors << 'missing positive'
    end
    if t = s.scan(/Total Deaths:\s([\d]+)/).first
      h[:deaths] = string_to_i(t[0])
    elsif (t=tables.select {|i| i=~/Hawaii deaths/}.first) && t =~ /Hawaii deaths:\s([\d]+)/
      h[:deaths] = string_to_i($1)
    else
      @errors << 'missing deaths'
    end

    # county cases
    # hospitalized is in PR
    @driver.navigate.to 'https://health.hawaii.gov/news/covid-19-updates/'
    url = @driver.page_source.scan(/https:\/\/[^'"]+daily-news-digest-[^'"]+/)[0]
    @driver.navigate.to url
    s = @driver.page_source.gsub(',','')
    @s += "\nBREAK\n" + s
    if @driver.find_elements(class: 'primary-content')[0].text.gsub(',','') =~ /Hawai.?i Totals\s\d+\s\d+\s(\d+)\s(\d+)/
      h[:tested] = string_to_i($2)
    else
      byebug unless @auto_flag
      @warnings << 'missing tested'
    end
    h
  end

  def parse_ia(h)
    crawl_page
    if  @driver.find_elements(class: 'full')[0].text.gsub(',','') =~ /there have been (\d+) negative COVID-19 test results/
      h[:negative] = string_to_i($1)
    else
      @errors << 'missing negative'
    end
    if @driver.page_source =~ /<iframe src=\"https:\/\/iowa\.maps\.arcgis\.com([^"]+)"/
      @url = 'https://iowa.maps.arcgis.com' + $1
    else # might be captcha
      if @auto_flag
        @errors << 'missing dash url, possible captcha'
        return h
      end
      puts "check if captcha, missing @url"
      byebug
      nil
    end
    url_death = @driver.page_source.scan(/https:\/\/[^'"]+maps\.arcgis\.com\/apps\/opsdashboard[^'"]+/)[-1]
    crawl_page
    sec = SEC/2
    loop do
      sec -= 1
      sleep 1
      puts "sleeping...#{sec}"
      x = @driver.find_elements(class: 'dock-container')[0]
      if x && (x=x.text.gsub(',','')) =~ /\nConfirmed Cases\n([^\n]+)\n/
        h[:positive] = string_to_i($1)
        @s += "\nBREAK\n" + x
        break
      elsif sec == 0
        @errors << 'missing positive'
        break
      end
    end
    crawl_page url_death
    sec = SEC/2
    loop do
      sec -= 1
      sleep 1
      puts "sleeping...#{sec}"
      if @driver.page_source.gsub(',','').scan( /"\s*Deceased ([\d]+)\s*"/).first
        h[:deaths] = string_to_i($1)
        break
      elsif sec == 0
        @errors << 'missing deaths'
        break
      end
    end
    # TODO counties is available in x
    # age in root page
    h
  end

  def parse_id(h)
    crawl_page
    @s = @driver.page_source
    s = @driver.find_elements(class: 'wp-block-column').map {|i| i.text.gsub(',','')}.select {|i| i=~/Deaths/}[0]
    if s && s =~ /(\d+)\sCases\s/
      h[:positive]=$1.to_i
    else
      @errors << 'missing positive'
    end
    if s && s =~ /(\d+)\sDeaths\s/
      h[:deaths] = $1.to_i
    else
      @errors << 'missing deaths'
    end
    puts "manual tested"
    byebug unless @auto_flag
=begin
    @s = @driver.find_elements(class: 'wp-block-column')[0].text.gsub(',','').gsub(/\s+/,' ')
    if (x=(@s =~ /Public Health District County Cases Deaths/)) &&
       @s[x..-1] =~ / TOTAL\*? ([0-9]+) ([0-9]+) /
      h[:deaths] = string_to_i($2)
    else
      byebug unless @auto_flag
      @errors << 'missing deaths, run manually'
    end
    if @s =~ /Number of people tested through the Idaho Bureau of Laboratories\*? ([0-9]+)/
      h[:tested] = string_to_i($1)
    else
      @errors << 'missing tested'
    end
=end
    h
  end

  def parse_il(h)
    crawl_page
    cols = (s=@driver.find_elements(class: "flex-container")[0].text).gsub(',','').split("\n").map {|i| i.strip}.select {|i| i.size>0}
    @s += "\nBREAK\n" + s
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Positive/}.first
      h[:positive] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing positive'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Deaths/}.first
      h[:deaths] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing deaths'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Total Tests Performed/i}.first
      h[:tested] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing tested'
    end
    h
  end

  def parse_in(h)
    url = 'https://www.coronavirus.in.gov/map/test.htm'
    crawl_page url
    sleep 3
    @s = @driver.find_elements(class: 'card').map {|i| i.text.gsub(',','')}.join("|")
    # Total Positive Cases\n13680|Total Deaths\n741|Total Tested\n75553
    if @s =~ /Total Positive Cases\n(\d+)/
      h[:positive] = $1.to_i
    else
      @errors << 'missing positive'
    end
    if @s =~ /Total Deaths\n(\d+)/
      h[:deaths] = $1.to_i
    else
      @errors << 'missing deaths'
    end
    if @s =~ /Total Tested\n(\d+)/
      h[:tested] = $1.to_i
    else
      @errors << 'missing tested'
    end
    h
  end

  def parse_ks(h)
    crawl_page
    sec = SEC/10
    loop do
      @s = @driver.page_source.gsub(',','')
      if @s =~ /(\d+) Confirmed Positive Test Res/
        if h[:positive] != (t=$1.to_i)
          h[:positive] = t
          byebug unless @auto_flag
          @errors << 'missing negative and deaths, do manually'
        end
        break
      end
      sec -= 1
      if sec == 0
        @errors << 'parse failed'
        break
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
    puts 'pdf might have more data'
    h
  end

  def parse_ky(h)
    crawl_page
    cols = (s=@driver.find_elements(class: 'alert-success')[0].text).gsub(',','').split("\n").map {|i| i.strip}.select {|i| i.size >0}
    @s += "\nBREAK\n" + s
    if (x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Number Tested:/}.first) && x[0] =~ /^Number Tested: ([0-9]+)/
      h[:tested] = string_to_i($1)
    else
      @errors << 'missing tested'
    end
    if (x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Positive:/}.first) && x[0] =~ /^Positive: ([0-9]+)/
      h[:positive] = string_to_i($1)
    else
      @errors << 'missing positive'
    end
    if (x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Deaths:/}.first) && x[0] =~ /^Deaths: ([0-9]+)/
      h[:deaths] = string_to_i($1)
    else
      @errors << 'missing deaths'
    end
    #url = 'https://governor.ky.gov/news'
    byebug unless @auto_flag
    h
  end

  def parse_la(h)
    crawl_page
    if @driver.page_source =~ /src="https:\/\/www.arcgis.com([^"]+)/
      crawl_page('https://www.arcgis.com' + $1)
    else
      @errors << 'link failed'
      return h
    end
    sec = SEC/3
    loop do
      sec -= 1
      puts "sleeping...#{sec}"
      sleep 1
      if sec <=0
        @errors << 'failed'
        break
      end
      begin
        @s = @driver.find_elements(class: 'layout-reference')[0].text.gsub(',','')
      rescue
        @s = ''
      end
      if @s =~ /Data updated: ([^\n ]+)/
      
        h[:date] = $1.strip
      end
      if @s =~ /\n(\d+)\nCases Reported/
        h[:positive] = string_to_i($1)
        if @s =~ /\nDeaths Reported\n(\d+)/
          h[:deaths] = string_to_i($1)
          if @s =~ /\nCommercial Tests\n(\d+)/
            h[:tested] = string_to_i($1)
            if @s =~ /(\d+)\nby State Lab/
              h[:tested] += string_to_i($1)
              break
            end
          end
        end
      elsif sec <= 0
        @errors << 'parse failed'
        break
      end
    end # loop
    unless h[:date]
      @warnings << 'missing date'
    end
    h
  end

  def parse_ma(h)
    crawl_page
    sec = SEC/3
    loop do
      @s = @driver.find_elements(class: 'page-content')[0].text
      if @s =~ /\nConfirmed cases of COVID-19 ([^\n]+)\n/
        h[:positive] = string_to_i($1)
        break
      elsif sec == 0
        @errors << 'missing positive'
        break
      end
      sec -= 1
      puts "sleeping...#{sec}"
      sleep 1
    end
    puts "pdf? manual entry of tested from pdf"
    if @driver.page_source =~ /([^'"]+covid-19-cases-in-massachusetts-as[^'"]+)/
      url = 'https://www.mass.gov' + $1
      `curl #{url} -o #{@path}#{@st}/#{@filetime}_1.pdf`
      `open #{@path}#{@st}/#{@filetime}_1.pdf` unless @auto_flag
      reader = PDF::Reader.new("#{@path}#{@st}/#{@filetime}_1.pdf")
=begin
      result = reader.page(1).text.gsub(/\s+/,' ').gsub(',','')
      rows = reader.page(1).text.split("\n").map {|i| i.gsub(/\s+/,' ').gsub(',','')}
      j = rows.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^County/}.first[1]
      i = 0
      h[:counties] = []
      loop do
        j += 1
        break if i > 100 || rows[j] =~ /^Unknown/ || rows[j] =~ /^Sex/
        if rows[j] =~ /^([A-Z][^\d]+)(\d+)/
          h_county = {}
          h_county[:name] = $1
          h_county[:positive] = string_to_i($2)
          h[:counties] << h_county
        end
        i += 1
      end
      if h[:counties].size < 13
        @errors << 'missing counties'
      end
=end
      result = reader.page(1).text.gsub(/\s+/,' ').gsub(',','')
      if result =~ /(\d+) Attributed to COVID-19/
        h[:deaths] = string_to_i($1)
      else
        @errors << 'missing deaths'
      end
      result = reader.page(4).text.gsub(/\s+/,' ').gsub(',','')
      if result =~ /Total ?Patients ?Tested\*? [\d]+ ([\d]+)/
        h[:tested] = string_to_i($1) 
      else
        @errors << 'missing tested'
      end
    else
      @errors << 'missing pdf'
    end 
    h
  end

  def parse_md(h)
    # TODO county, age
    crawl_page
    sec = SEC/3
    loop do
      @s = @driver.find_elements(class: 'markdown-card').map {|i| i.text.gsub(',','')}.select {|i| i=~/Number of confirmed deaths/}[0]
      if @s =~ /Number of confirmed cases : (\d+)\nNumber of negative test results : (\d+)\nNumber of confirmed deaths : (\d+)/
        h[:positive] = string_to_i($1)
        h[:negative] = string_to_i($2)
        h[:deaths] = string_to_i($3)
byebug unless @auto_flag
        break
      end
      puts "sleeping...#{sec}"
      sleep(1)
      sec -= 1
      if sec == 0
        @errors << 'parse failed'
        break
      end
    end

if false
    if (@driver.find_elements(class: 'container').map {|i| i.text}.select {|i| i=~/\nNumber of Deaths:([^\n]+)\n/}[0] =~ /\nNumber of Deaths:([^\n]+)\n/)
      h[:deaths] = string_to_i($1)
    else
      @errors << "missing deaths"
    end
    if (@driver.find_elements(class: 'container').map {|i| i.text}.select {|i| i=~/\nNumber of negative test results:([^\n]+)\n/}[0] =~ /\nNumber of negative test results:([^\n]+)\n/)
      h[:negative] = string_to_i($1)
    else
      @errors << "missing negative"
    end
end
    # TODO raw not fully saved
    h
  end

  def parse_me(h)
    crawl_page
    #byebug
    cols = @doc.css('table').map {|i| i.text}.select {|i| i=~/Confirmed Cases/}.first.split("\n").map {|i| i.strip}.select {|i| i.size > 0}
    if cols.size == 10
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Deaths/}.first
      h[:deaths] = string_to_i(cols[x[1]+4])
    else
      @errors << 'missing deaths'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Confirmed Cases/}.first
      h[:positive] = string_to_i(cols[x[1]+4])
    else
      @errors << 'missing positive'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Presumptive Positive Cases/}.first
      h[:positive] = 0 unless h[:positive]
      h[:positive] += string_to_i(cols[x[1]+4])
    else
      @warnings << 'missing positive 2'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Negative Tests/}.first
      h[:negative] = string_to_i(cols[x[1]+4])
    else
      @warnings << 'missing negative'
    end
    elsif cols.size == 6
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Confirmed Cases/}.first
      h[:positive] = string_to_i(cols[x[1]+2])
    else
      @errors << 'missing positive'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Negative Tests/}.first
      h[:negative] = string_to_i(cols[x[1]+2])
    else
      @errors << 'missing negative'
    end
    else
      @errors << 'table failed'
    end
    if x = cols.select {|i| i=~/^Updated: (.*)/}.first
      x=~/^Updated: (.*)/
      h[:date] = $1
    else
      @errors << 'missing date'
    end
    # counties
    # demographics
    h
  end

  def parse_mi(h)
    # TODO sex, age, hospitalization
    crawl_page
    x = @driver.find_elements(class: 'moreLink').select {|i| i.text =~ /Cumulative Data/i}.first
    unless x
      @errors << 'button not found'
      return h
    end
    x.click
    if @s =~ /Updated COVID-19 reported data has been delayed and will be displayed as soon as available/
      @errors << 'MI data being prepared'
      return h
    end
    sleep 1
    cols = @driver.find_elements(class: 'fullContent')[0].text.gsub(',','').split("\n").map {|i| i.strip}.select {|i| i.size>0}
    if (x = cols.select {|i| i=~ /^Totals/}.first) && x=~/Totals\s(\d+)\s(\d+)/
      h[:positive] = string_to_i($1)
      h[:deaths] = string_to_i($2)
    else
      @errors << 'missing positive'
    end

# cols = @driver.find_elements(class: 'fullContent')[0].text.split("\n").map {|i| i.strip}
# h[:tested] = (3..53).to_a.map {|i| cols[i].split("\s")[-2].gsub(',','').to_i }.sum



    @s = @driver.find_element(id: 'bodyWrapper').text.gsub(',','')
    if x = @s.scan(/Grand Total ([\d]+) ([\d]+) [\d]+/).first
      h[:tested] = string_to_i(x[0]) + string_to_i(x[1])
    else
      @errors << 'missing tested'
    end
    cols = @s.split("\n").map {|i| i.strip}
    x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v =~ /County Cases Reported Deaths/}.first
    i = x[1] + 1
    h[:counties] = []
    while !(cols[i] =~ /Other/) && !(cols[i] =~ /Out of State/) &&
      (cols[i] =~ /([^\d]+)[^\d]+([\d]+)[^\d]+([\d]+)/ ||
       cols[i] =~ /([^\d]+)[^\d]+([\d]+)/)
      h_county = {}
      h_county[:name] = $1
      h_county[:positive] = $2.to_i
      h_county[:deaths] = $3.to_i
      h[:counties] << h_county
      i += 1
    end
    if h[:counties].size < 58
      @errors << 'missing counties'
    end
    h
  end

  def parse_mn(h)
    crawl_page
    sec = SEC
    cols = []
    loop do
      begin
        cols = @driver.find_elements(id: 'body')[0].text.gsub(',','').split("\n").map {|i| i.strip}.select {|i| i.size > 0}
        break
      rescue => e
        puts "sleeping...#{sec}"
        sleep 1
        sec -= 1
        break if sec == 0
      end
    end
    if x = cols.select {|v,i| v=~/Total approximate number of completed tests:/}.first
      h[:tested] = string_to_i(x.strip.split.last)
    else
      @errors << 'missing tested'
    end
=begin
    if x = cols.select {|v,i| v=~/Approximate number of completed tests from external/}.first
      h[:tested] = 0 unless h[:tested]
      h[:tested] += string_to_i(x.strip.split.last)
    else
      @errors << 'missing tested2'
    end
=end
    if (x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Total Positive: /i}.first) &&
      x[0] =~ /Total Positive: ([0-9]+)/i
      h[:positive] = string_to_i($1)
    else
      @errors << 'missing positive'
    end
    if (x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Deaths:/}.first) &&
      x[0] =~ /^Deaths:\s?([0-9]+)/
      h[:deaths] = string_to_i($1)
    end
    if (x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Total deaths: /}.first) &&
      x[0] =~ /^Total deaths: ([0-9]+)/
      h[:deaths] = string_to_i($1)
    end
    unless h[:deaths]
      @errors << 'missing deaths'
    end
    # TODO tested no longer available
    h
  end  

  def parse_mo(h)
    # TODO click to get county
    crawl_page
    @s.gsub!(',','')
    if @s =~ /Cases in Missouri: ([0-9]+)/
      h[:positive] = string_to_i($1)
    else
      @errors << 'missing positive'
    end
    if @s =~ /Total Deaths: ([0-9]+)/
      h[:deaths] = string_to_i($1)
    else
      @errors << 'missing deaths'
    end
    if @s =~ /Patients tested in Missouri[^\d]+([0-9]+)/
      h[:tested] = string_to_i($1)
    else
      @errors << 'missing tested'
    end

    h
  end

  def parse_ms(h)
    crawl_page
# TODO get counties
    if (s=@driver.find_elements(id: 'msdhTotalCovid-19Cases')[0]) && 
      (s.text.gsub(',','') =~ /\nTotal\s([0-9]+)\s([0-9]+)/)
      h[:positive] = string_to_i($1)
      h[:deaths] = string_to_i($2)
    else
      @errors << 'missing positive and deaths'
    end
    s = @doc.css('body').text.gsub(',','')
    if s =~ /Total individuals tested for COVID-19 statewide[^\d]+([0-9]+)/i
      h[:tested] = string_to_i($1)
    else
      @errors << 'missing tested'
    end
    # counties in a nice table
    h
  end

  def parse_mt(h)
    crawl_page
    if @s =~ /<a href="https:\/\/montana\.maps\.arcgis\.com([^"]+)"/
      @url = 'https://montana.maps.arcgis.com' + $1
    else
      @errors << 'map url not found'
      return h
    end
puts @url
    crawl_page
    sec = SEC
    loop do
      if @url = @driver.page_source.scan(/https:\/\/experience\.arcgis\.com\/[^'"]+/).first
        break
      elsif sec == 0
        @errors << 'map url2 not found'
        return h
      end
      sec -= 1
      puts "sleeping...#{sec}"
      sleep 1
    end
puts @url
    crawl_page
(1..1).to_a.each do |outer_loop|
    sec = SEC
    loop do
      if (@url = @driver.page_source.scan(/https:\/\/montana.maps.arcgis.com[^'"]+/).first) || 
         (@url = @driver.page_source.scan(/https:\/\/experience\.arcgis\.com\/[^'"]+/).first)
        break
      elsif sec == 0
        @errors << 'map url3 not found'
        return h
      end
      sec -= 1
      puts "sleeping...#{sec}"
      sleep 1
    end
    puts @url
    crawl_page
end
    sec = SEC/2
    loop do
      @s = @driver.find_elements(class: 'dashboard-page')[0].text
# County is available
      flag = false
      if @s =~ /Total Confirmed Cases\n([^\n]+)\n/
        h[:positive] = string_to_i($1)
        sleep 2
      else
        flag = true
      end
      if @s =~ /Total Tests\n([^\n]+)\n/
        h[:tested] = string_to_i($1)
      else
        #flag = true
      end
      if @s =~ /Total Deaths\n([^\n]+)\n/
        h[:deaths] = string_to_i($1)
      else
        flag = true
      end
      if flag
        sec -= 1
        if sec == 0
          @errors << 'parse failed'
          return h
        end
        puts "sleeping...#{sec}"
        sleep 1
      else
        break
      end
    end
    h
  end  

  def parse_nc(h)
    crawl_page
    @s = @driver.find_elements(class: 'field-item').map {|i| i.text.gsub(',','')}.select {|i| i=~/Completed Tests/}[0]
    if @s =~ /\sCases Deaths Completed Tests Currently Hospitalized Number of Counties\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)/
      h[:tested] = $3.to_i
      h[:positive] = $1.to_i
      h[:hospitalized] = $4.to_i
      h[:deaths] = $2.to_i
    else
      byebug unless @auto_flag
      @errors << 'parse failed'
    end
    return h

    sec = SEC
    cols = []
    loop do
      begin
        cols = @driver.find_elements(class: 'content').map {|i| i.text}.select {|i| i=~/NC Completed Tests/i}.last.split("\n").map{|i| i.strip}.select{|i| i.size>0}
        byebug if cols.size != 13 && !@auto_flag
        break
      rescue => e
        sleep 1
        puts "sleeping...#{sec}"
        sec -= 1
        break if sec == 0
      end
    end
byebug
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^NC Cases/}.first
      h[:positive] = string_to_i(cols[x[1]+4])
    else
      @errors << 'missing positive'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^NC Deaths/i}.first
      h[:deaths] = string_to_i(cols[x[1]+4])
    else
      @errors << 'missing deaths'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^NC Completed Tests/i}.first
      h[:tested] = string_to_i(cols[x[1]+4])
    else
      @errors << 'missing tested'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Hospitalized/i}.first
      h[:hospitalized] = string_to_i(cols[x[1]+4])
    else
      @errors << 'missing hospitalized'
    end
    h
  end

  def parse_nd(h)
    if @auto_flag
      puts 'skipping ND'
      h[:skip] = true
      return h
    end
    crawl_page
    puts "image file for ND"
    h[:tested] = 11317# HARDCODE
    h[:positive] = 365
    h[:negative] = 10952
    h[:hospitalized] = 44
    h[:pending] = 0
    h[:deaths] = 9  # TODO manual
    pngs = @s.scan(/files\/documents\/Files\/MSS\/coronavirus[^'"]+/)
    i = 0
    for png in pngs
      i += 1
      url = 'https://www.health.nd.gov/sites/www/' + png
      `curl #{url} -o #{@path}#{@st}/#{@filetime}_#{i}.png`
    end
    puts 'manual entry from image'
    byebug 
    h
  end  

  def parse_ne(h)
    crawl_page
    if @s =~ /<strong>.Updated&#58\; <\/strong>([^<]+)</
      h[:date] = $1
    else
      @warnings << "missing date"
    end
    if url = @driver.page_source.scan(/https:\/\/arcg.is[^'"]+/).first
    else
      @errors << 'missing url'
      return h
    end
    crawl_page url
    sec = SEC
    loop do
      @s = @driver.find_element(class: 'dashboard-page').text.gsub(',','')
      flag = true
      if @s =~ /Total positive cases\n([\d]+)/
        h[:positive] = string_to_i($1)
      else
        flag = false
      end
      if @s =~ /Total tested\n([\d]+)/
        h[:tested] = string_to_i($1)
      else
        flag = false
      end
      if @s =~ /Deaths\n([\d]+)/
        h[:deaths] = string_to_i($1)
      else
        flag = false
      end
      if flag
        break
      end
      sec -= 1
      if sec == 0
        @errors << 'parse failed'
        break
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
    h
  end  

  def parse_nh(h)
    crawl_page
    #byebug
    cols = @doc.css('table')[0].text.split("\n").map {|i| i.strip}.select {|i| i.size > 0}
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Number of Persons with covid/i}.first
      h[:positive] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing positive'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Deaths Attributed to COVID/i}.first
      h[:deaths] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing deaths'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Have Been Hospitalized /i}.first
      h[:hospitalized] = string_to_i(cols[x[1]+1])
    else
      byebug unless @auto_flag
      @errors << 'missing hospitalized'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Persons with Test Pending /i}.first
      h[:pending] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing pending'
    end
=begin
# only for state lab tests, negatives have more labs
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Persons with Specimens Submitted/i}.first
      h[:tested] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing tested'
    end
=end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Persons Being Monitored/i}.first
      h[:monitored] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing monitored'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Persons Tested Negative/i}.first
      h[:negative] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing negative'
    end
    h
  end

  def parse_nj(h)
    crawl_page
    if (@s = @driver.find_elements(class: 'card-body').map {|i| i.text }.select {|i| i=~/Negative Results/}[0]) &&
      @s.gsub(',','') =~ /Positive[^\d]+(\d+)\nDeaths[^\d]+(\d+)\nNegative Results[^\d]+(\d+)/
      h[:positive] = $1.to_i
      h[:deaths] = $2.to_i
      h[:negative] = $3.to_i
    else
      @errors << 'parse failed'
    end
    url = 'https://covid19.nj.gov/'
    crawl_page url
    url = 'https://' + @driver.page_source.scan(/maps\.arcgis\.com\/apps\/opsdashboard\/index\.html[^'"]+/)[0]
    crawl_page url
    sec = SEC
    county_pos = 0
    loop do 
      cols = (@driver.find_element(class: 'dashboard-page').text.split("\n").map {|i| i.strip}) rescue []
      if cols.size > 0
        if (x=cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Bergen County/}.first) &&
          (y=cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Salem County/}.first)
          county_count = ((y[1]-x[1])/3+1)
          if county_count == 21
            h[:counties] = []
            county_pos = 0
            county_count.times do |i|
              h_county = {}
              j = i*3+x[1]
              h_county[:name] = cols[j]
              h_county[:positive] = string_to_i(cols[j+1].split("\s").first)
              county_pos += string_to_i(cols[j+1].split("\s").first)
              h_county[:deaths] = string_to_i(cols[j+2].split("\s").first)
              h[:counties] << h_county
            end
            break
          end    
        end
      end
      sec -= 1
      if sec == 0
        @errors << 'counties failed'
        break
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
    if h[:counties].size < 21
      @errors << 'missing counties'
    end
    if h[:positive] != county_pos
      #@errors << 'county pos do not add up'
      # provisional pos are not counted
    end
    h
  end

  def parse_nm(h)
    crawl_page
    sec = SEC/3
    cols = []
    loop do
      begin
        cols = @driver.find_elements(class: "et_pb_text_inner").map {|i| i.text}.select {|i| i=~/COVID-19 Test Results in N/}[0].split("\n")
        @s = @driver.find_elements(class: "et_pb_text_inner").map {|i| i.text}.select {|i| i=~/COVID-19 Test Results in N/}[0]
        break
      rescue => e
        if sec == 0
          @errors << 'failed to parse table'
          return h
        end
        sec -= 1
        puts "sleeping...#{sec}"
        sleep 1
      end
    end # loop
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Positive/}.first
      h[:positive] = string_to_i(x[0].split.last)
    else
      @errors << 'missing positive'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Negative/}.first
      h[:negative] = string_to_i(x[0].split.last)
    else
      @warnings << 'missing negative'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Total Tests/}.first
      h[:tested] = string_to_i(x[0].split.last)
    else
      @errors << 'missing tested'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/COVID-Related Deaths in N/i}.first
      h[:deaths] = string_to_i(x[0].split.last)
    else
      @errors << 'missing deaths'
    end
    h
  end

  def parse_nv(h)
    crawl_page
    if @s =~ /"https:\/\/app\.powerbigov([^"]+)"/
      @url = 'https://app.powerbigov' + $1
    else
      @errors << 'bi url not found'
      return h
    end
    crawl_page
    @s = ''
    sec = SEC / 3
    loop do
      puts "sleeping...#{sec}"
      sleep 1
      sec -= 1
      if sec == 0
        @errors << 'failed to load'
        return h
      end
      @driver.find_elements(class: 'pbi-glyph-chevronleftmedium').first.click rescue nil
      x = @driver.find_elements(class: 'landingController')[0]
      @s = x.text.gsub(',','') if x
      flag = true
      if @s =~ /\n([0-9]+)Deaths Statewide\n/
        h[:deaths] = string_to_i($1)
      else
        flag = false
      end
      if @s =~ /\n([0-9K]+)People Tested\n/
        h[:tested] = string_to_i($1)
      else 
        flag = false
      end

      if (@s =~ /All\n([0-9]+)Negative\n([0-9]+)Positive\nResult/)
        h[:negative] = string_to_i($1)
        h[:positive] = string_to_i($2)
      else
        flag = false
      end
      return h if flag
    end    
    h
  end

  def parse_ny(h)
    if @auto_flag
      puts "skipping NY"
      h[:skip] = true
      return h
    end
    crawl_page
    # url = 'https://covid19tracker.health.ny.gov/views/NYS-COVID19-Tracker/NYSDOHCOVID-19Tracker-Fatalies?%3Aembed=yes&%3Atoolbar=no&%3Atabs=n'
    byebug unless @auto_flag
    return h

=begin
    rows = @doc.css('table')[0].text.gsub(',','').split("\n").map {|i| i.strip}.select {|i| i.size>0}
    county_pos = 0
    if rows[-2] == "Total Number of Positive Cases"
      h[:positive] = rows[-1].to_i
      county_count = ((rows.size-4)/2)
      if rows[1] == "Positive Cases" && county_count > 54
        h[:counties] = []
        county_count.times do |i|
          h_county = {}
          h_county[:name] = rows[i*2+2]
          h_county[:positive] = string_to_i(rows[i*2+3])
          county_pos += h_county[:positive]
          h[:counties] << h_county
        end
      else
        @errors << 'incorrect table'
      end
    else
      @errors << "missing positive"
    end
    if h[:counties].size < 53
      @errors << 'missing counties'
    end
=end
    # TOOD death data
    unless @auto_flag
      url = 'https://www1.nyc.gov/assets/doh/downloads/pdf/imm/covid-19-daily-data-summary.pdf'
      `curl #{url} -o #{@path}#{@st}/#{@filetime}_1.pdf`
      `open #{@path}#{@st}/#{@filetime}_1.pdf` 
      reader = PDF::Reader.new("#{@path}#{@st}/#{@filetime}_1.pdf")
      result = reader.page(1).text.gsub(/\s+/,' ').gsub(',','')
      if result =~ /Deaths ([\d]+)/
        h[:deaths] = string_to_i($1) # from nyc report TODO
      else
        @errors << 'nyc missing deaths'
      end
    end
    #@url = 'https://coronavirus.health.ny.gov/home'
    #crawl_page
    h
  end

  def parse_oh(h)
    crawl_page
    sec = SEC/3
    cols = []
    loop do
      begin
        cols = @driver.find_elements(class: 'stats-cards__container')[0].text.split("\n").map {|i| i.strip}.select {|i| i.size > 0}
        break
      rescue => e
        if sec == 0
          @errors << 'failed to parse table'
          return h
        end
        sec -= 1
        puts "sleeping...#{sec}"
        sleep 1
      end
    end # loop
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Confirmed Cases/}.first
      h[:positive] = string_to_i(cols[x[1]-1])
    else
      @errors << 'missing positive'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Total Deaths/}.first
      h[:deaths] = string_to_i(cols[x[1]-1])
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Number of Deaths/}.first
      h[:deaths] = string_to_i(cols[x[1]-1])
    end
    unless h[:deaths]
      @errors << 'missing deaths'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Number of Hospitalizations in Ohio/}.first
      h[:hospitalized] = string_to_i(cols[x[1]-1])
    else
      @errors << 'missing hospitalized'
    end
    # counties available
    # https://coronavirus.ohio.gov/wps/wcm/connect/gov/c831a1c5-1a91-41ba-837d-ddbcba2af6c5/3-30+Presser+Final+%281%29.pdf?MOD=AJPERES&CONVERT_TO=url&CACHEID=ROOTWORKSPACE.Z18_M1HGGIK0N0JO00QO9DDDDM3000-c831a1c5-1a91-41ba-837d-ddbcba2af6c5-n4IWbZu
    url = 'https://coronavirus.ohio.gov/wps/portal/gov/covid-19/dashboards/key-metrics-cases/'
    crawl_page url
    if @auto_flag
      @errors << 'tested manual required'
    else
      crawl_page url
      puts 'manually enter tested'
      byebug
    end
    byebug unless @auto_flag
    h
  end

  def parse_ok(h)
    crawl_page
    byebug unless @auto_flag
    #byebug
    cols = @doc.css('table').map {|i| i.text}.select {|i| i=~/Oklahoma Test Results/}.last.split("\n").select {|i| i.strip.size > 0}
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Positive \(In-State\)/}.first
      h[:positive] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing positive'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Positive \(Out-of-State\)/}.first
      h[:positive] = 0 unless h[:positive]
      h[:positive] += string_to_i(cols[x[1]+1])
    else
      @warnings << 'missing positive 2'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Deaths/}.first
      h[:deaths] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing deaths'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Total Cumulative Negative Specimens/}.first
      h[:negative] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing negative'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Total Cumulative Number of Specimens to Date/}.first
      h[:tested] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing tested'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/PUIs Pending Results/}.first
      h[:pending] = string_to_i(cols[x[1]+1])
    else
      (@warnings << 'missing pending') if cols.size > 11
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Total Cumulative Hospitalizations/}.first
      h[:hospitalized] = string_to_i(cols[x[1]+1])
    else
      @warnings << 'missing hospitalized'
    end
    h
  end  

  def parse_or(h)
    crawl_page
    sec = SEC/3
    cols = []
    loop do
      begin
        cols = @driver.find_elements(class: 'card-body').map {|i| i.text.gsub(',','')}.select {|i| i=~/Total deaths/i}.first.split("\n")

        break
      rescue => e
        if sec == 0
          @errors << 'parse failed'
          return h
        end
        sec -= 1
        puts "sleeping...#{sec}"
        sleep 1
      end
    end # loop
    if (x = cols.select {|v,i| v=~/^Positive ([0-9]+)/}.first) && x=~/^Positive ([0-9]+)/
      h[:positive] = string_to_i($1)
    else
      @errors << 'missing positive'
    end
    if (x = cols.select {|v,i| v=~/^Negative ([0-9]+)/}.first) && x=~/^Negative ([0-9]+)/
      h[:negative] = string_to_i($1)
    else
      @errors << 'missing negative'
    end
    if (x = cols.select {|v,i| v=~/^Pending ([0-9]+)/}.first) && x=~/^Pending ([0-9]+)/
      h[:pending] = string_to_i($1)
    else
      @warnings << 'missing pending'
    end
    if (x = cols.select {|v,i| v=~/^Total .* tested/}.first) 
      h[:tested] = string_to_i(x.split.last)
    else
      @errors << 'missing tested'
    end
    if (x = cols.select {|v,i| v=~/^Total Deaths/i}.first)
      h[:deaths] = string_to_i(x.split.last)
    else
      @errors << 'missing deaths'
    end
    # counties
    # hospitalized
    h
  end  

  def parse_pa(h)
    crawl_page
    @s = @driver.find_elements(class: 'content-container')[0].text.gsub(',','').gsub('*','')
    if @s =~ /Total Cases Deaths Negative\n(\d+)\n(\d+)\n(\d+)/
      h[:negative] = string_to_i($3)
      h[:positive] = string_to_i($1)
      h[:deaths] = string_to_i($2)
    else
      @errors << 'parse failed'
      byebug unless @auto_flag
      return h
    end
    rows = @driver.find_elements(class: 'ms-rteTable-default').map {|i| i.text.gsub(',','')}.select {|i| i=~/County\s+Number of Ca/}.first.split("\n")
    rows.shift
    h[:counties] = []
    for r in rows
      if (r =~ /(.*) (\d+) (\d+)/) || (r =~ /(.*) (\d+)/)
        h_county = {}
        h_county[:name] = $1
        h_county[:positive] = $2.to_i
        h_county[:deaths] = $3.to_i
        h[:counties] << h_county
      else
        @errors << 'county table parse error'
      end 
    end
    if h[:counties].size < 56
      @errors << 'missing counties'
    end
    h
  end

  def parse_pr(h)
    crawl_page
    sec = SEC
    cols = []
    table=nil
    loop do
      begin
        table = @driver.find_elements(class: 'ms-rteTableEvenCol-10').first
        break
      rescue => e
        puts "sleeping...#{sec}"
        sleep 1
        sec -= 1
        break if sec == 0
      end
    end
    h2 = table.find_elements(tag_name: 'h2').first
    h[:tested] = h2.text.gsub(/,/,'').to_i
    table = nil
    loop do
      begin
        table = @driver.find_elements(class: 'ms-rteTableOddCol-10').first
        break
      rescue => e
        puts "sleeping...#{sec}"
        sleep 1
        sec -= 1
        break if sec == 0
      end
    end
    h2 = table.find_elements(tag_name: 'h2').first
    h[:positive] = h2.text.gsub(/,/,'').to_i
    loop do
      begin
        table = @driver.find_elements(class: 'ms-rteTableEvenCol-10')[2]
        break
      rescue => e
        puts "sleeping...#{sec}"
        sleep 1
        sec -= 1
        break if sec == 0
      end
    end
    h2 = table.find_elements(tag_name: 'h2').first
    h[:deaths] = h2.text.gsub(/,/,'').to_i
    h
  end  

  def parse_ri(h)
    crawl_page
    sec = SEC/3
    loop do
      begin
        break if (@s = @driver.find_elements(class: 'master')[0].text.gsub(',','')) =~ /Number of Rhode Island COVID-19 associated fatalities/
      rescue => e
      end
      sec -= 1
      if sec == 0
        @errors << 'failed to parse'
        return h
      end
      puts "sleeping...#{sec}"
      sleep(1)
    end
    cols = @s.split("\n")
    if (x = cols.select {|v,i| v=~/^Number of Rhode Island COVID-19 positive cases/}.first)
      h[:positive] = string_to_i(x.strip.split.last)
    else
      @errors << 'missing pos'
    end
    if (x = cols.select {|v,i| v=~/^Number of people who have had negative test results/}.first)
      h[:negative] = string_to_i(x.strip.split.last)
    else
      @errors << 'missing neg'
    end
    if (x = cols.select {|v,i| v=~/^Number of people for whom tests are pending/}.first)
      h[:pending] = string_to_i(x.strip.split.last)
    else
      @warnings << 'missing pending'
    end
    if (x = cols.select {|v,i| v=~/^Number of Rhode Island.*fatalities/}.first)
      h[:deaths] = string_to_i(x.strip.split.last)
    else
      @errors << 'missing deaths'
    end
    h
  end

  def parse_sc(h)
    crawl_page
    sec = SEC
    rows = []
    loop do
      begin
        rows = @driver.find_elements(id: 'dmtable')[0].text.gsub(',','').split("\n").map {|i| i.strip}.select {|i| i.size > 0}
        raise if rows.size == 0
        break
      rescue => e
        sec -= 1
        if sec == 0
          @errors << 'failed to parse'
          return h
        end
        puts "sleeping...#{sec}"
        sleep(1)
      end
    end
    if (x=rows.select {|i| i=~/Total negative tests /}[0]) && x.gsub(',','') =~ /Total negative tests ([0-9]+)/
      h[:negative] = string_to_i($1)
    else
      @errors << "missing negative"
    end
=begin
    if (x=rows.select {|i| i=~/Positive tests/}[0]) && x.gsub(',','') =~ /Positive tests ([0-9]+)/
      h[:positive] = string_to_i($1)
    else
      @errors << "missing positive"
    end
=end
    if @driver.page_source =~ /"([^"]+)arcgis\.com([^"]+)"/
      crawl_page($1 + 'arcgis.com' + $2)
      sec = SEC
      loop do
        if @driver.page_source =~ /src=\"https:\/\/arcg.is([^"]+)/
          crawl_page('https://arcg.is' + $1)
          @s = @driver.find_elements(class: 'dashboard-page').first.text
          if @s =~ /Deaths in Individuals with COVID-19 infection\n([^\n]+)\n/
            h[:deaths] = string_to_i($1)
          else
            @errors << 'missing deaths inner'
          end
          if @s =~ /\nTotal Positive Cases\n([^\n]+)/
            h[:positive] = string_to_i($1)
          else
            @errors << 'missing positive inner'
          end
# TODO get counties
          break
        end
        sec -= 1
        break if sec == 0
        puts "sleeping...#{sec}"
        sleep 1
      end
    else
      @errors << 'missing iframe'
    end
    # TODO tested
    h
  end

  def parse_sd(h)
    crawl_page
    tables = @doc.css('table').map {|i| i.text.gsub(',','').gsub(/\s+/,' ').gsub('*','')}
    if (t = tables.select {|i| i=~/SOUTH DAKOTA CASE COUNTS/}[0]) &&
      t =~ /Positive ([0-9]+) Negative ([0-9]+) Pending ([0-9]+)/
      h[:positive] = string_to_i($1)
      h[:negative] = string_to_i($2)
      h[:pending] = string_to_i($3)
      h[:tested] = h[:positive] + h[:negative] + h[:pending]
    else
      @errors << "missing pos neg pending"
    end
    if (t = tables.select {|i| i=~/COVID-19 IN SOUTH DAKOTA/}[0]) &&
      #t =~ /Cases ([0-9]+) Deaths ([0-9]+) Recovered ([0-9]+)/
      t =~ /Deaths\s(\d+)\sRecovered\s(\d+)\s/
      #h[:hospitalzed] = string_to_i($2)
      h[:deaths] = string_to_i($1)
      h[:recovered] = string_to_i($2)
    else
      @errors << "missing deaths"
    end
    h
  end  

  def parse_tn(h)

    if @auto_flag
      puts "skipping TN"
      h[:skip] = true
    end

    `rm ~/Downloads/TDH-2019-Novel-Coronavirus-Epi-and-Surveillance.pdf`
    crawl_page
=begin
    s = @doc.css('table')[0].text.gsub(',','')
    if s =~ /Laboratory Type\n\nPositive Test\n\nNegative Tests\n\nTotal/ &&
      s =~ /\nTotal\n\n([0-9]+)\n\n([0-9]+)\n\n([0-9]+)/
      h[:positive] = string_to_i($1)
      h[:negative] = string_to_i($2)
      h[:tested] = string_to_i($3)
    else     
      byebug unless @auto_flag
      @errors << 'parse failed' 
    end
    s = @doc.css('table').map {|i| i.text.gsub(',','')}.select {|i| i=~/Fatalities/}.first
    if s =~ /Fatalities\n([0-9]+)/
      h[:deaths] = string_to_i($1)
    else
      @errors << 'missing deaths'
    end
=end
    `open ~/Downloads/TDH-2019-Novel-Coronavirus-Epi-and-Surveillance.pdf` unless @auto_flag
    byebug unless @auto_flag
    `mv ~/Downloads/TDH-2019-Novel-Coronavirus-Epi-and-Surveillance.pdf #{@path}#{@st}/#{@filetime}_1.pdf`
    h
  end

  def parse_tx(h)
=begin
    crawl_page
    if @url = @s.scan(/[^'"]+maps\.arcgis\.com\/apps\/opsdashboard[^'"]+/).first
      crawl_page
    else
      @errors << 'missing url'
      return h
    end
=end
# TODO this might break 
@url = 'https://txdshs.maps.arcgis.com/apps/opsdashboard/index.html#/ed483ecd702b4298ab01e8b9cafc8b83'
crawl_page
    sec = SEC
    loop do
      @s = @driver.find_elements(class: 'dashboard-page')[0].text
      flag = true
      if x = @s.scan(/([^\n]+)\nTotal tests/i).first
        h[:tested] = string_to_i(x[0])
      else
        flag = false
      end
      if x = @s.scan(/\n([^\n]+)\nCases Reported\n([^\n]+)\nFatalities\n/).first
        h[:positive] = string_to_i(x[0])
        h[:deaths] = string_to_i(x[1])
      else
        flag = false
      end 
      sec -= 1
      if flag
        break
      elsif sec == 0
        @errors << 'parse failed'
        break
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
    h
  end

  def parse_ut(h)
    crawl_page
    @s = @driver.find_elements(id: 'dashboard-container')[0].text
    if @s =~ /(\d+)\nTotal COVID-19 Cases\n(\d+)\nTotal Reported People Tested\n(\d+)\nTotal COVID-19 Hospitalizations\n(\d+)\nTotal COVID-19 Deaths/
      h[:positive] = string_to_i($1)
      h[:tested] = string_to_i($2)
      h[:hospitalized] = string_to_i($3)
      h[:deaths] = string_to_i($4)
    else
byebug
      @errors << 'missing positive'
    end
    h
  end

  def parse_va(h)
    crawl_page
=begin
    if @auto_flag
      puts "skipping VA"
      h[:skip] = true
      return h
    end
=end
    if @driver.page_source =~ /<iframe src=\"https:\/\/public\.tableau\.com([^"]+)"/
      @url = 'https://public.tableau.com' + $1
    else
      @errors << 'missing tableau url'
      return h
    end 
    crawl_page
    sec = SEC/4
    loop do
      begin
        sec -= 1
        @driver.find_element(:xpath, '//*[@id="download-ToolbarButton"]').click
        break
      rescue => e
        if sec == 0
          @errors << 'click failed'
          break
        end
        puts "sleeping...#{sec}"
        sleep(1)
      end
    end
    @driver.find_element(:xpath, '//*[@id="DownloadDialog-Dialog-Body-Id"]/div/button[4]').click
    sleep 3
    @driver.find_element(:xpath, '//*[@id="PdfDialog-Dialog-Body-Id"]/div/div[2]/div[4]/button').click
    sleep 5
    `mv "../../Downloads/Virginia COVID-19 Dashboard.pdf" #{@path}#{@st}/#{@filetime}_1.pdf`
    reader = PDF::Reader.new("#{@path}#{@st}/#{@filetime}_1.pdf")
    #reader = PDF::Reader.new(File.join(ENV['userprofile'], "Downloads", "Virginia COVID-19 Dashboard.pdf"))
    result = reader.page(1).text
    # TODO save this pdf in /data/va dir
    # might want to reference other text to make sure it hasn't changed
    # note that the ordering of numbers is different
    numbers = result.gsub(',','').scan(/\s(\d+)\s/)
    numbers4 = (0..3).to_a.map {|z| string_to_i(numbers[z][0]) }.sort
    h[:deaths],
    h[:hospitalized],
    h[:positive],
    h[:tested] = numbers4
    h
  end
  
  def parse_vt(h)
    crawl_page
    #byebug
    if @s =~ /Last updated: ([^<]+)</
      h[:date] = $1.strip
    else
      @warnings << "missing date"
    end
    cols = @doc.css('table')[0].text.split("\n").map {|i| i.strip}.select {|i| i.size > 0}
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Positive test results/}.first
      h[:positive] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing positive'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/People being monitored/}.first
      h[:monitored] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing monitored'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/People who have completed monitoring/}.first
      h[:monitored_cumulative] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing monitored cum'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Total tests/}.first
      h[:tested] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing tested'
    end
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/Deaths/}.first
      h[:deaths] = string_to_i(cols[x[1]+1])
    else
      @errors << 'missing deaths'
    end
    h
  end

  def parse_wa(h)
=begin
    crawl_page
    sec = SEC
    urls = []
    loop do
      urls = @driver.page_source.scan(/https:\/\/[^'"]*powerbi\.com[^'"]+/)
      break if urls.size > 1
      sec -= 1
      if sec == 0
        @errors << 'url missing'
        return h
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
    crawl_page urls[1]
    sec = SEC
    loop do
      begin
        #cols = @driver.find_elements(class: 'value').map {|i| i.text.gsub(',','').strip }.select {|i| (i=~/^\d+$/) && i.to_i>0 }.map {|i| i.to_i}.sort
        #@s = @driver.find_elements(class: 'landingController')[0].text.gsub(',','')
        #if @s =~ /Confirmed Cases\n Total Deaths\s+(\d+)\s(\d+)\s/
        @s = @driver.find_elements(class: 'landingController').map {|i| i.text.gsub(',','')}.select {|i| i=~/Total Deaths/}.first
        if @s
          @s.gsub!("\n",'|')
          @s.gsub!(/\s+/,' ')
          if @s =~ /Cases|Total Deaths|Total tests|Percent Positive|(\d+)|(\d+)|(\d+)/
            h[:positive] = $1.to_i
            h[:deaths] = $2.to_i
            h[:tested] = $3.to_i
            break
          end
        end
      rescue
      end
      sec -= 1
      if sec == 0
        @errors << 'parse failed, no data'
        break
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
=end
=begin
    if (i=cols.find_index("County Positive/Confirmed Cases Deaths"))
      i += 1
      h[:counties] = []
      while !(cols[i]=~/^Unassigned/) && !(cols[i]=~/^Total/) &&
        cols[i].gsub(',','') =~ /(.*)\s([\d]+)\s([\d]+)/
          h_county = {}
          h_county[:name] = $1
          h_county[:positive] = string_to_i($2)
          h_county[:death] = string_to_i($3)
          h[:counties] << h_county
        i += 1
      end
    else
      @errors << 'counties failed'
    end
    if h[:counties].size < 34
      @errors << 'missing counties'
    end 
=end


    crawl_page

    sec = SEC
    cols = []
    loop do
      begin
        cols = @driver.find_elements(id: 'dnn_content')[0].text.split("\n").map {|i| i.strip.gsub(',','')}.select {|i| i.size > 0}
      rescue
        sec -= 1
        puts 'sleeping'
        sleep 1
      end
      if sec == 0
        @errors << 'cols fail'
        break
      end
      break if cols.size > 0
    end
    x = cols.select {|i| i=~/^Negative\s+([^\s+]+)/}
    if x.size == 1 && x[0] =~ /^Negative\s+([^\s+]+)/
      h[:negative] = string_to_i($1)
    else
      @errors << 'negative'
    end
    if (x=cols.select {|i| i=~/^Total / && i.split.size==3}).size > 0 && (x=x[0].split) && x[0]=='Total'
      h[:positive] = string_to_i(x[1])
      h[:deaths] = string_to_i(x[2])
    else
      @errors << 'missing deaths'
    end
    if (i=cols.find_index("County Confirmed Cases Deaths"))
      i += 1
      h[:counties] = []
      while !(cols[i]=~/^Unassigned/) && !(cols[i]=~/^Total/) &&
        cols[i].gsub(',','') =~ /(.*)\s([\d]+)\s([\d]+)/
          h_county = {}
          h_county[:name] = $1
          h_county[:positive] = string_to_i($2)
          h_county[:death] = string_to_i($3)
          h[:counties] << h_county
        i += 1
      end
    else
      @errors << 'counties failed'
    end
    if h[:counties].size < 34
      @errors << 'missing counties'
    end 

    h
  end

  def parse_wi(h)
    # direct data available here:
    # https://dhsgis.wi.gov/server/rest/services/DHS_COVID19/COVID19_WI/MapServer/3/query?where=1%3D1&outFields=*&outSR=4326&f=json
    # counties also available 
    crawl_page
    if @s =~ /As of ([^<]+)</
      h[:date] = $1.strip
    else
      @errors << "missing date"
    end
    @s = @driver.find_elements(id: 'main')[0].text.gsub(',','')
    if @s =~ /Negative Test Result (\d+)\nPositive Test Result (\d+)\nHospitalizations [^\n]+\nDeaths (\d+)\n/
      h[:positive] = string_to_i($2)
      h[:negative] = string_to_i($1)
      h[:deaths] = string_to_i($3)
    else
      @errors << "missing cases"
    end
    h
  end

  def parse_wv(h)
    crawl_page
    sec = SEC/5
    url = ''
    loop do
      url = @driver.page_source.scan(/https:[^'"]+powerbigov.us[^'"]+/).first
      break if url
      sec -= 1
      if sec == 0
        @errors << 'missing url'
        break
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
    crawl_page url
    sec = SEC/2
    loop do
      @s = @driver.find_element(class: 'landingController').text rescue nil
      if @s && @s.gsub(',','') =~ /Reported to\s?WVDHHR\n(\d+)\n/
        h[:tested] = $1.to_i
        if @s.gsub(',','') =~ /Resident Positive Cases\n(\d+)\n/
          h[:positive] = $1.to_i
          if @s.gsub(',','') =~ /Resident Deaths\n(\d+)/
            h[:deaths] = $1.to_i
            break
          end
        end    
      end
      sec -= 1
      if sec == 0
        @errors << 'missing url'
        break
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
    h
  end

  def parse_wy(h)
    crawl_page
    s = @driver.find_element(class: 'page').text
    #byebug
    if s =~ /At this time there are ([^\s]+) laboratory/
      h[:positive] = string_to_i($1)
    else
      @errors << "cases found"
    end
    h[:tested] = 0
    if @s =~ /Tests completed at Wyoming Public Health Laboratory: ([^<]+)</
      h[:tested] += string_to_i($1)
    else
      @errors << "missing tested"
    end
    if @s =~ /Tests completed at CDC lab: ([^<]+)</
      h[:tested] += string_to_i($1)
    else
      @errors << "missing tested 2"
    end
    if @s =~ /Tests reported by commercial labs: ([^<]+)</
      h[:tested] += string_to_i($1)
    else
      @errors << "missing tested 3"
    end
    url = 'https://health.wyo.gov/publichealth/infectious-disease-epidemiology-unit/disease/novel-coronavirus/covid-19-map-and-statistics/'
    crawl_page url
    puts 'death manual'
    byebug unless @auto_flag
    h
  end

  ################
  # counties

  def parse_scc(h)
    crawl_page
    url = @s.scan(/https:\/\/[^'"]+powerbigov[^'"]+/).first
    crawl_page url
    sec = SEC/3
    loop do
      @s = @driver.find_element(class: 'landingController').text.gsub(',','') rescue ''
      if @s =~ /\n(\d+)\nCases by Age Group/
        h[:positive] = $1.to_i
        break
      end
      sec -= 1
      if sec == 0
        @errors << 'parse failed'
        break
      end
      puts "sleeping...#{sec}"
      sleep 1
    end
    # deaths manual
    byebug unless @auto_flag
    h
  end

  def parse_smc(h)
    crawl_page
#h[:positive] = 309
#h[:deaths] = 10
byebug unless @auto_flag
=begin
    if @doc.css('table')[0].text.gsub(/\s+/,' ').gsub(',','') =~ /Positive (\d+) Deaths (\d+)/
      h[:positive] = $1.to_i
      h[:deaths] = $2.to_i
    else
      @errors << 'parse failed'
    end
=end
    h
  end

  def parse_alameda(h)
    crawl_page
    sleep 2 
    @s = @driver.find_elements(class: 'contacts_table')[0].text.gsub(',','') 
    if @s =~ /Positive Cases: (\d+)\*?\nDeaths: (\d+)\*?/
      h[:positive] = $1.to_i
      h[:deaths] = $2.to_i
    else
      @errors << 'parse failed'
    end
    h
  end

  def parse_sf(h)
    crawl_page
    if @s =~ /Total Positive Cases: (\d+)/
      h[:positive] = $1.to_i
    else
      @errors << 'missing positive'
    end
    if @s =~ /Deaths: (\d+)/
      h[:deaths] = $1.to_i
    else
      @errors << 'missing deaths'
    end
    h
  end

  def parse_santacruz(h)
    crawl_page
    if @doc.css('table').map {|i| i.text}.select {|i| i =~ /Verified Cases/}[0].gsub(/\s+/,' ').gsub(',','') =~ /(\d+)[^\d]+\s*\/\s*(\d+)\s+COVID-19 Case In/
      h[:positive] = $1.to_i
      h[:deaths] = $2.to_i
    else
      @errors << 'parse failed'
    end
    h
  end

  ######################################

  # look for a word on the webpage
  # deprecated, not used
  def search_term(word='death')
    doc_text = @doc.text.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    if (i = (doc_text =~ /#{word}/i)) && !(doc_text =~ /birth/i)
      puts "found #{word} in #{@st}"
      puts doc_text[(i-30)..(i+30)]
      return true
    end
    @driver.navigate.to @url
    if (i = (@driver.page_source =~ /#{word}/i)) && !(doc_text =~ /birth/i)
      puts "found #{word} in #{@st}"
      puts @driver.page_source[(i-30)..(i+30)]
      return true
    end
    false
  end

  # convert a string to an int
  def string_to_i(s)
    if !s
      byebug unless @auto_flag
      nil
    end
    return s if s.class == Integer
    if s.class == String
      s = s.strip.gsub(',','').gsub('-',' ').gsub(/\s+/,' ').downcase
      x = @h_numbers[s]
      return x if x
    end
    return 0 if s == "--"
    if s =~/^([0-9]+)\s?K/
      return $1.to_i * 1000
    end
    if s =~ /Appx\. (.*)/
      s = $1
    elsif s =~ /~(.*)/
      s = $1
    elsif s =~ /App/
      byebug unless @auto_flag
      ''
    end
    case s.strip
    when "zero"
      0
    when "one"
      1
    when "two"
      2
    when "three"
      3
    when "four"
      4
    when "five"
      5
    when "six"
      6
    when "seven"
      7
    when "eight"
      8
    when "nine"
      9
    when "ten"
      10
    when 'eleven'
      11
    else
      if s =~ /in progress/
        nil
      else
        s = s.strip.gsub('‡','').gsub(',','')
        if s =~ /([0-9]+)/
          $1.to_i
        else
          puts "Please fix. Invalid number string: #{s}"
          temp = nil
          byebug unless @auto_flag
          return temp
        end
      end
    end
  end

  def initialize

profile = Selenium::WebDriver::Firefox::Profile.new
#profile.add_extension("/path/to/extension.xpi")
profile['browser.download.dir'] = '/Users/danny/Downloads'
#profile['browser.download.folderList'] = 2
profile['browser.helperApps.neverAsk.saveToDisk'] = "application/pdf, application/csv"
profile['pdfjs.disabled'] = true
options = Selenium::WebDriver::Firefox::Options.new(profile: profile)

    @driver = Selenium::WebDriver.for :firefox, options: options
    @path = 'data/'
    # load previous numbers
    lines = open('all.csv').readlines.map {|i| i.split("\t")}
    # previous state stats
    @h_prev = Hash.new({})
    lines.each do |st, tested, positive, deaths, junk|
      st.downcase!
      @h_prev[st] = {}
      @h_prev[st][:tested] = tested.to_i if tested.size > 0
      @h_prev[st][:positive] = positive.to_i if positive.size > 0
      @h_prev[st][:deaths] = deaths.to_i if deaths.size > 0
    end

    @h_numbers = {}
    1000.times {|i| @h_numbers[i.humanize.gsub('-',' ')] = i}
  end

  def method_missing(m, h)
    puts "method_missing called on state: #{@st}"
    if @auto_flag
      h[:skip] = true
      return h
    end
    @driver.navigate.to @url
    byebug
    h
  end

  def crawl_page(url = @url)
    begin
      @driver.navigate.to(url)
      open("#{@path}#{@st}/#{@filetime}_#{@page_count+=1}", 'w') do |f| 
        f.puts url
        f.puts @driver.page_source
      end
    rescue => e
      @errors << "crawl_page failed: #{e.inspect}"
    end
  end

  # main execution loop
  # 
  # default is to run all states in automatic mode
  # or you can specifiy the list of states to run
  # if auto_flag is false, will prompt you for certain states
  #
  def run(crawl_list = [], auto_flag = true, debug_page_flag = false)
    @auto_flag = auto_flag
    h_all = []
    errors_crawl = []
    warnings_crawl = []
    skipped_crawl = []
    tested   = {:all => 0}
    positive = {:all => 0}
    deaths   = {:all => 0}
    skip_flag = OFFSET
    @filetime = Time.now.to_s[0..18].gsub(' ', '-').gsub(':', '.')

    url_list = (open('states.csv').readlines.map {|i| i.strip.split("\t")}.map {|st, url| [st.downcase, url]})
    url_list += (open('counties.csv').readlines.map {|i| i.strip.split("\t")}.map {|st, url| [st.downcase, url]})
    for @st, @url in url_list
      @page_count = 0 # used for naming saved page
      next if crawl_list.size > 0 && !(crawl_list.include?(@st))
      puts "CRAWLING: #{@st}"
      skip_flag = false if @st == OFFSET
      next if skip_flag
      next if SKIP_LIST.include?(@st)
      unless Dir.exist?("#{@path}#{@st}")
        Dir.mkdir("#{@path}") unless Dir.exist?("#{@path}")
        Dir.mkdir("#{@path}#{@st}")
      end 
    
      @s = `curl -s #{@url}`
      @doc = Nokogiri::HTML(@s)
      @errors = []
      @warnings = []
      h = {:ts => Time.now, :st => @st, :source_urls => [@url], :source_texts => []}
      begin
        h = send("parse_#{@st}", h)
      rescue => e
        @errors << "parse_#{@st} crashed: #{e.inspect}"
      end

      if h[:skip]
        skipped_crawl << @st
      else
        open("#{@path}#{@st}/#{@filetime}", 'w') {|f| f.puts @s} # @s might be modified in parse
        count = 0
        tested_new = 0
        count += 1 if h[:tested]
        if h[:positive]
          count += 1
          tested_new += h[:positive]
        end
        if h[:negative]
          count += 1
          tested_new += h[:negative]
        end
        if h[:pending]
          count += 1
          tested_new += h[:pending]
        end
        # do this in the second parse_log.rb step
        # h[:tested] = tested_new unless h[:tested]

        if @h_prev[@st][:tested] == h[:tested] && @h_prev[@st][:positive] == h[:positive] && @h_prev[@st][:deaths] == h[:deaths]
          # no change
        elsif @h_prev[@st][:tested] == h[:tested] && @h_prev[@st][:positive] == h[:positive]
          puts "only deaths changed for #{@st}"
          puts "old h: #{@h_prev[@st]}"
          puts "new h: #{h}"
          unless @auto_flag
            @driver.navigate.to(@url) rescue nil
            byebug
            puts
          end
        elsif @h_prev[@st][:positive] == h[:positive]
          if h[:tested] 
            puts "tested different, positives same for #{@st}"
            puts "old h: #{@h_prev[@st]}"
            puts "new h: #{h}"
            unless @auto_flag
              @driver.navigate.to(@url) rescue nil
              byebug
              puts
            end
          else
            # missing tested in new
          end
        elsif !h[:positive]
          puts "missing positive for #{@st}"
          puts "old h: #{@h_prev[@st]}"
          puts "new h: #{h}"
          unless @auto_flag
            @driver.navigate.to(@url) rescue nil
            byebug
            puts
          end
        elsif h[:positive] < @h_prev[@st][:positive].to_i
          puts "positive decreased for #{@st}"
          puts "old h: #{@h_prev[@st]}"
          puts "new h: #{h}"
          unless @auto_flag
            @driver.navigate.to(@url) rescue nil
            byebug
            puts 
          end
        elsif ((h[:tested] && tested_new > h[:tested]) || count == 3 || (count == 4 && (h[:tested] != (h[:positive] + h[:negative] + h[:pending])))) && !h[:skip]
          puts "please double check stats, for #{@st}:"
          puts "old h: #{@h_prev[@st]}"
          puts "new h: #{h}"
          unless @auto_flag
            @driver.navigate.to(@url) rescue nil
            byebug
            puts
          end
        end

        positive[:all] += h[:positive].to_i
        positive[@st.to_sym] = h[:positive]
        deaths[:all] += h[:deaths].to_i
        deaths[@st.to_sym] = h[:deaths]
        tested[:all] += h[:tested].to_i
        tested[@st.to_sym] = h[:tested]

        h[:error] = @errors

        warnings_crawl << { @st => @warnings } if @warnings.size > 0

        if @errors.size != 0 && !h[:skip]
          errors_crawl << { @st => @errors }
          puts
          puts "ERROR in #{@st}: #{@errors.inspect}"
          puts "new h: #{h}"
          unless @auto_flag
            byebug
            puts
          end
        elsif debug_page_flag && !@auto_flag 
          puts
          puts "DEBUG PAGE FLAG"
          puts @st
          puts h.inspect
          puts
          puts({:tested => h[:tested], :pos => h[:positive], :neg => h[:negative], :pending => h[:pending]}.inspect)
          #@driver.navigate.to @url
          byebug 
          puts
        end

        h_all << h  
        # save parsed h
        open("#{@path}#{@st}.log",'a') {|f| f.puts h.inspect} if h && h.size > 0 && !(h[:skip])

        puts ["Update for #{@st}", "new: [#{h[:tested]}, #{h[:positive]}, #{h[:deaths]}]", 
          "old: [#{@h_prev[@st][:tested]}, #{@h_prev[@st][:positive]}, #{@h_prev[@st][:deaths]}]"].join("\t")

      end # unless h[:skip]
    end # states @st loop

    puts
    puts "positive:"
    puts positive.inspect
    puts
    puts "deaths:"
    puts deaths.inspect
    puts
    puts "tested:"
    puts tested.inspect
    puts
    puts "#{errors_crawl.size} errors:"
    puts errors_crawl.map {|i| i.inspect}
    puts
    puts "#{warnings_crawl.size} warnings:"
    puts warnings_crawl.map {|i| i.inspect}
    puts
    puts "#{skipped_crawl.size} skipped:"
    puts skipped_crawl.inspect
    puts
    
    puts "done."
    errors_crawl.map {|i| i.keys.first}
  end # end run

end # Crawler class
