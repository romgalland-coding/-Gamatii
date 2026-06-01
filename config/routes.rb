Rails.application.routes.draw do
  devise_for :users

  resources :games, only: [:index, :show]

  resources :lists do
    resources :list_games, only: [:create, :destroy]
  end

  resources :quizzs do
    resources :quizz_games, only: [:create, :destroy]
  end

  root "games#index"
end
