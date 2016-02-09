# =====================================================================
# Web app infrastructure for Django project
# Copyright (C) 2016 Stefan Dieterle
# e-mail: golgoths@yahoo.fr
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# =====================================================================

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
