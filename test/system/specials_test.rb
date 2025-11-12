require "application_system_test_case"

class SpecialsTest < ApplicationSystemTestCase
  setup do
    @special = specials(:one)
  end

  test "visiting the index" do
    visit specials_url
    assert_selector "h1", text: "Specials"
  end

  test "should create special" do
    visit specials_url
    click_on "New special"

    fill_in "Closed time", with: @special.closed_time
    fill_in "Day of week", with: @special.day_of_week
    fill_in "Description", with: @special.description
    fill_in "Open time", with: @special.open_time
    fill_in "Special name", with: @special.special_name
    fill_in "Title", with: @special.title
    click_on "Create Special"

    assert_text "Special was successfully created"
    click_on "Back"
  end

  test "should update Special" do
    visit special_url(@special)
    click_on "Edit this special", match: :first

    fill_in "Closed time", with: @special.closed_time.to_s
    fill_in "Day of week", with: @special.day_of_week
    fill_in "Description", with: @special.description
    fill_in "Open time", with: @special.open_time.to_s
    fill_in "Special name", with: @special.special_name
    fill_in "Title", with: @special.title
    click_on "Update Special"

    assert_text "Special was successfully updated"
    click_on "Back"
  end

  test "should destroy Special" do
    visit special_url(@special)
    accept_confirm { click_on "Destroy this special", match: :first }

    assert_text "Special was successfully destroyed"
  end
end
