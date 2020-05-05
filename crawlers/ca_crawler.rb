# frozen_string_literal: true

require './crawlers/base_crawler.rb'

class CaCrawler < BaseCrawler

  protected

  def _find_positive
    #@results[:positive] = w[1].to_i
  end

  def _find_deaths
    #w = /(\d+)\s*Deaths/.match(image_string)
    #return unless w
    #@results[:deaths] = w[1].to_i
  end

  def _find_tested
    #w = /(\d+)\s*Tested/.match(image_string)
    #return unless w
    #@results[:tested] = w[1].to_i
  end
end
