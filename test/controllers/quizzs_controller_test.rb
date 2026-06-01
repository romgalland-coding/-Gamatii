require "test_helper"

class QuizzsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get quizzs_index_url
    assert_response :success
  end

  test "should get show" do
    get quizzs_show_url
    assert_response :success
  end

  test "should get new" do
    get quizzs_new_url
    assert_response :success
  end

  test "should get create" do
    get quizzs_create_url
    assert_response :success
  end

  test "should get edit" do
    get quizzs_edit_url
    assert_response :success
  end

  test "should get update" do
    get quizzs_update_url
    assert_response :success
  end

  test "should get destroy" do
    get quizzs_destroy_url
    assert_response :success
  end
end
