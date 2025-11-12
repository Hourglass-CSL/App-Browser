require "test_helper"

class DisplayControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get display_index_url
    assert_response :success
  end
end
