require "test_helper"

class QuizzGamesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get quizz_games_create_url
    assert_response :success
  end

  test "should get destroy" do
    get quizz_games_destroy_url
    assert_response :success
  end
end
