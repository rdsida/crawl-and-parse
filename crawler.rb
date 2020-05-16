# Used for making sure we drop data files in the correct path:
BASEDIR = __dir__

require_relative './lib/cli'
require_relative './lib/utils'
require_relative './crawlers/base_crawler'
Dir['./crawlers/states/*.rb'].sort.each { |file| require file }

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

# Once the individual parsers are extracted from this class, we can turn it into
# a supervisor/runner
class Crawler < BaseCrawler
  # parse_XXX methods for the 50 US states and DC

  def parse_ak(h)
    AkCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_al(h)
    AlCrawler.new(driver: @driver, url: @url, st: @st).call
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
    CaCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_co(h)
    CoCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  # TODO death number is words
  def parse_ct(h)
    CtCrawler.new(driver: @driver, url: @url, st: @st).call
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

  # https://news.delaware.gov/2020/03/29/public-health-announces-1-additional-death-18-additional-positive-cases-in-delaware/
  # https://news.delaware.gov/2020/03/31/covid-19-in-delaware-public-health-announces-3-additional-deaths-55-more-positive-cases-in-delaware/
  def parse_de(h)
    DeCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_fl(h)
    FlCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_ga(h)
    GaCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_hi(h)
    HiCrawler.new(driver: @driver, url: @url, st: @st).call
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
    KyCrawler.new(driver: @driver, url: @url, st: @st).call
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
    MaCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_md(h)
    MdCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_me(h)
    MeCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_mi(h)
    MiCrawler.new(driver: @driver, url: @url, st: @st).call
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
    MsCrawler.new(driver: @driver, url: @url, st: @st).call
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
    NcCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_nd(h)
    crawl_page
    stats = {positive: /(.+)\nPositive Cases/, tested: /(.+)\nTotal Tested/, deaths: /(.+)\nDeaths/, hospitalized: /(.+)\nTotal Hospitalized/}
    circles = @driver.find_elements(class: "circle").map{|c| c.text}
    circles.each do |c|
      stats.each do |k, v|
        if c =~ v
          h[k] = string_to_i($1)
        end
      end #stat
    end #circle
    stats.keys.reject{|i| i == :hospitalized }.each do |stat|
      @errors << "missing #{stat.to_s}" unless h[stat]
    end
    h
  end

  def parse_ne(h)
    NeCrawler.new(driver: @driver, url: @url, st: @st).call
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
    NjCrawler.new(driver: @driver, url: @url, st: @st).call
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
    NvCrawler.new(driver: @driver, url: @url, st: @st).call
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
    if x = cols.map.with_index {|v,i| [v,i]}.select {|v,i| v=~/^Total Cases/}.first
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
    OkCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_or(h)
    OrCrawler.new(driver: @driver, url: @url, st: @st).call
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
    PrCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_ri(h)
    RiCrawler.new(driver: @driver, url: @url, st: @st).call
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
    SdCrawler.new(driver: @driver, url: @url, st: @st).call
  end

  def parse_tn(h)
    TnCrawler.new(driver: @driver, url: @url, st: @st).call
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
    WaCrawler.new(driver: @driver, url: @url, st: @st).call
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
    sec = SEC/3
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
    sleep 6
    loop do
      cards = @driver.find_elements(class: "card").map{|c| string_to_i c.text}
      cards_indexes = {tested: 3, positive: 2, deaths: 0}
      cards_indexes.each do |k, v|
        h[k] = cards[v]
        @errors << "#{k.to_s} missing" unless h[k] && h[k] > 0
      end
      data_parsed = h.select{|k, v| [:tested, :positive, :deaths].include? k}.values.all?{|v| v.class == Integer && v > 0}
      break if data_parsed
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


  # Options is a struct created by the CLI class
  def initialize(crawl_list)
    @options = CrawlAndParse.options
    @crawl_list = crawl_list

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

  # main execution loop
  #
  # default is to run all states in automatic mode
  # or you can specifiy the list of states to run
  # if auto_flag is false, will prompt you for certain states
  #
  def run
    @auto_flag = CrawlAndParse.auto
    debug_page_flag = CrawlAndParse.debug
    crawl_list = @crawl_list
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
      @results = results_init
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
      h = {:ts => Time.now, :st => @st, :source_urls => [@url], :source_texts => [], :errors => []}
      begin
        h = send("parse_#{@st}", h)
        @errors += h[:errors]
      rescue => e
        raise unless CrawlAndParse.nofail

        byebug unless @auto_flag
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
    @driver.quit
  end # end run

end # Crawler class
