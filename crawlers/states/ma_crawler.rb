# frozen_string_literal: true

class MaCrawler < BaseCrawler
  protected

  def _set_up_page
    raw_data_link = @driver.find_elements(xpath: './/a').find { |t| /\/doc\/covid-19-raw-data-\S*\/download/.match?(t.attribute('href')) }.attribute('href')
    destination_folder = "data/#{@st}/#{Time.now.strftime('%Y%m%d%H%M')}/"
    zip_file_name = "#{destination_folder}raw_data.zip"
    Dir.mkdir("#{destination_folder}") unless Dir.exist?("#{destination_folder}")
    `curl #{raw_data_link} -o #{zip_file_name}`
    Zip::File.open(zip_file_name) do |zip_file|
      zip_file.each do |entry|
        puts "Extracting #{entry.name}"
        fpath = File.join(destination_folder, entry.to_s)
        FileUtils.mkdir_p(File.dirname(fpath))
        zip_file.extract(entry, fpath)
      end
    end

    @case_csv = CSV.read("#{destination_folder}Cases.csv", headers: true)
    @deaths_csv = CSV.read("#{destination_folder}DeathsReported.csv", headers: true)
    @county_csv = CSV.read("#{destination_folder}County.csv", headers: true)
    @testing_csv = CSV.read("#{destination_folder}Testing2.csv", headers: true)
    @hospitalized_csv = CSV.read("#{destination_folder}Hospitalization from Hospitals.csv", headers: true)
    unless @case_csv && @deaths_csv && @county_csv && @testing_csv && @hospitalized_csv
      @errors << "Problem accessing pdfs for Ma Crawler"
    end
  end

  def _find_positive
    if @case_csv
      @results[:positive] = @case_csv[-1]['Cases']&.to_i
    else
      @errors << "Missing case csv for Ma Crawler"
    end
  end

  def _find_deaths
    if @deaths_csv
      @results[:deaths] = @deaths_csv[-1]['Deaths']&.to_i
    else
      @errors << "Missing deaths csv for Ma Crawler"
    end
  end

  def _find_tested
    if @testing_csv
      @results[:tested] = @testing_csv[-1]['Total']&.to_i
    else
      @errors << "Missing tested csv for Ma Crawler"
    end
  end

  def _find_counties
    if @county_csv
      max_date = @county_csv[-1]['Date']
      @county_csv.select { |t| t['Date'] == max_date }.each do |county|
        @results[:counties] << {
          name: county['County'],
          positive: county['Count'].to_i,
          deaths: county['Deaths'].to_i,
        }
      end
    else
      @errors << "Missing county csv for Ma Crawler"
    end
  end
end
