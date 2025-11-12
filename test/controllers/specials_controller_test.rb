require "test_helper"

class SpecialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @special = specials(:one)
  end

  test "should get index" do
    get specials_url
    assert_response :success
  end

  test "should get new" do
    get new_special_url
    assert_response :success
  end

  test "should create special" do
    assert_difference("Special.count") do
      post specials_url, params: { special: { closed_time: @special.closed_time, day_of_week: @special.day_of_week, description: @special.description, open_time: @special.open_time, special_name: @special.special_name, title: @special.title } }
    end

    assert_redirected_to special_url(Special.last)
  end

  test "should show special" do
    get special_url(@special)
    assert_response :success
  end

  test "should get edit" do
    get edit_special_url(@special)
    assert_response :success
  end

  test "should update special" do
    patch special_url(@special), params: { special: { closed_time: @special.closed_time, day_of_week: @special.day_of_week, description: @special.description, open_time: @special.open_time, special_name: @special.special_name, title: @special.title } }
    assert_redirected_to special_url(@special)
  end

  test "should destroy special" do
    assert_difference("Special.count", -1) do
      delete special_url(@special)
    end

    assert_redirected_to specials_url
  end
end
