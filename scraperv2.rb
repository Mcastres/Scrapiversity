require 'colorize'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'selenium-webdriver'

def get_mails(url)
    doc = Nokogiri::HTML(url)
    mails = doc.xpath('//a[starts-with(@href, "mailto:")]/@href')
end

def save_mails(file, mails)
    i = 0
    mails.each do |mail|
        file << mail.to_s.gsub('mailto:', '') + "\n"
        puts "\t#{mail.to_s.gsub('mailto:', '')}".green
        i += 1
        break if i == 3
    end
end

def display(website)
    puts '-'*50
    puts "FROM"
    puts "\t#{website}"
    puts "GET"
end

# Selenium Options: --headless => No browser
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')

# Selenium Instance using chrome
driver = Selenium::WebDriver.for :chrome, :options => options
driver.manage.timeouts.page_load = 15

# Read the universities.json
uri = File.read('universities.json')

File.open('mails', 'a') do |file|
    # Parsing the json
    universities = JSON.parse(uri)
    universities.each do |university|
        next if university['country'] != 'United States'
        display(university['web_pages'][0])
        begin
            pages = ["contact", "contact-us", "about", "about-us"]
            pages.each do |page|
                driver.navigate.to university['web_pages'][0].to_s + page
                break unless driver.title.downcase.include? "page not found"
            end
            mails = get_mails(driver.page_source)
            save_mails(file, mails)
        rescue Selenium::WebDriver::Error::TimeOutError, Selenium::WebDriver::Error::UnknownError
            next
            puts "Aborted"
        end
    end
end
