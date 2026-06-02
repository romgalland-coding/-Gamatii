require "test_helper"

class QuizGamesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get quiz_games_create_url
    assert_response :success
  end

  test "should get destroy" do
    get quiz_games_destroy_url
    assert_response :success
  end
end
