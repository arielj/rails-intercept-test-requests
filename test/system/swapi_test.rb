require "application_system_test_case"

class IndexTest < ApplicationSystemTestCase
  test "The Star Wars API request" do
    visit root_path

    intercept("https://swapi.dev/api/planets/1/", "my mocked response")

    click_button "Make SWAPI request"

    assert_selector "#response", text: "my mocked response"
  end
end