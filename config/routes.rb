Rails.application.routes.draw do
  devise_for :users
  root "pages#home"
  get "discover", to: "pages#discover"

  # Recommendation chatbot hosted on the Discover page
  resources :chats, only: %i[show create] do
    resources :messages, only: [:create]
  end

  resources :games, only: [:show]

  # road for the game show using the rawg id, used for the discover page
  get "rawg_games/:rawg_id/preview", to: "games#rawg_preview", as: :rawg_game_preview

  resources :lists do
    collection do
      get :search_games
    end
    member do
      get :build
      post :like
    end
    resources :list_games, only: [:create]
  end

  resources :list_games, only: [:destroy]

  resources :quizzes, only: [] do
    member do
      get :autocomplete_games
    end
    collection do
      get :daily
    end
    resources :quiz_games, only: [:create]
  end

  resources :quiz_games, only: [:destroy]

  resource :profile, only: %i[show edit update] do
    get :settings
  end

  # Public user profiles + social graph
  resources :users, only: [:show] do
    member do
      get :followers
      get :following
    end
    resource :follow, only: %i[create destroy]
  end
end
