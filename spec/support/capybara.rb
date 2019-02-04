require "capybara/rails"
require "capybara/rspec"
require "selenium-webdriver"

WAIT_TIME = 1.minutes

# register chromedriver headless mode
Capybara.register_driver(:headless_chrome) do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[headless disable-gpu window-size=1920,1080, no-sandbox ignore-certificate-errors] }
  )

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: capabilities
  )
end
Capybara.default_driver = :headless_chrome
Capybara.javascript_driver = :headless_chrome

Capybara.configure do |config|
  config.default_max_wait_time = WAIT_TIME
  config.match = :one
  config.exact_options = true
  config.ignore_hidden_elements = true
  config.visible_text_only = true
  config.default_selector = :css
end
