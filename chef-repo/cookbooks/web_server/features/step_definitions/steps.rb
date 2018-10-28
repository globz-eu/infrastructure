require 'faraday'

Given(/^a url "(.*?)"$/) do |url|
  @url = url
end

When(/^an admin browses to the URL$/) do
  connection = Faraday.new(:url => @url) do |faraday|
    faraday.adapter Faraday.default_adapter
  end
  @page = connection.get('/').body
end

Then(/^the admin should see "(.*?)"$/) do |content|
  expect(@page).to include(content)
end
