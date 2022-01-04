require "rails_helper"

describe "SWAPI spec" do
  it "shows the response" do
    visit root_path

    intercept("https://swapi.dev/api/planets/1/", "my mocked response")

    click_button "Make SWAPI request"

    assert_selector "#response", text: "my mocked response"
  end
end