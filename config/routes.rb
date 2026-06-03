Rails.application.routes.draw do
  devise_for :users
  root "pages#home"
  get "discover", to: "pages#discover"

  resources :games, only: [:show]

  resources :lists do
    collection do
      get :search_games
    member do
      get :discover
    end
    resources :list_games, only: [:create]
  end

  resources :list_games, only: [:destroy]

  resources :quizzes, only: [:show] do
    collection do
      get :daily
    end
    resources :quiz_games, only: [:create]
  end

  resources :quiz_games, only: [:destroy]

  resource :profile, only: [:show, :edit, :update]
  resources :games, only: [:show] do
  collection do
    get :search
  end
end

end
