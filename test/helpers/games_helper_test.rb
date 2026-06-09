require "test_helper"

class GamesHelperTest < ActionView::TestCase
  test "rawg_card_meta builds genre · year · platforms from a RAWG hash" do
    game = {
      "genres" => [{ "name" => "Action" }],
      "released" => "2014-10-24",
      "platforms" => [
        { "platform" => { "name" => "Nintendo Switch" } },
        { "platform" => { "name" => "Wii U" } }
      ]
    }
    assert_equal "Action · 2014 · Switch / Wii U", rawg_card_meta(game)
  end

  test "rawg_card_meta omits missing parts" do
    assert_equal "RPG", rawg_card_meta({ "genres" => [{ "name" => "RPG" }] })
    assert_equal "", rawg_card_meta({})
  end
end
