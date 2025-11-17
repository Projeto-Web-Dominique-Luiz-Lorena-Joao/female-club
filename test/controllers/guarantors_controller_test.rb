require "test_helper"

class GuarantorsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get guarantors_index_url
    assert_response :success
  end

  test "should get show" do
    get guarantors_show_url
    assert_response :success
  end

  test "should get new" do
    get guarantors_new_url
    assert_response :success
  end

  test "should get create" do
    get guarantors_create_url
    assert_response :success
  end

  test "should get edit" do
    get guarantors_edit_url
    assert_response :success
  end

  test "should get update" do
    get guarantors_update_url
    assert_response :success
  end

  test "should get destroy" do
    get guarantors_destroy_url
    assert_response :success
  end
end
