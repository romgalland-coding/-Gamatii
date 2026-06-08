class AddPhotoUrlToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :photo_url, :string
  end
end
