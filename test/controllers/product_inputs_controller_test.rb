require "test_helper"

class ProductInputsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get product_inputs_index_url
    assert_response :success
  end

  test "should get show" do
    get product_inputs_show_url
    assert_response :success
  end

  test "should get new" do
    get product_inputs_new_url
    assert_response :success
  end

  test "should get create" do
    get product_inputs_create_url
    assert_response :success
  end

  test "should get edit" do
    get product_inputs_edit_url
    assert_response :success
  end

  test "should get update" do
    get product_inputs_update_url
    assert_response :success
  end

  test "should get destroy" do
    get product_inputs_destroy_url
    assert_response :success
  end
end
