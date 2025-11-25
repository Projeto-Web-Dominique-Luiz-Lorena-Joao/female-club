require "test_helper"

class ProductOutputsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get product_outputs_index_url
    assert_response :success
  end

  test "should get show" do
    get product_outputs_show_url
    assert_response :success
  end

  test "should get new" do
    get product_outputs_new_url
    assert_response :success
  end

  test "should get create" do
    get product_outputs_create_url
    assert_response :success
  end

  test "should get edit" do
    get product_outputs_edit_url
    assert_response :success
  end

  test "should get update" do
    get product_outputs_update_url
    assert_response :success
  end

  test "should get destroy" do
    get product_outputs_destroy_url
    assert_response :success
  end
end
