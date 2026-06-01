Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  resources :games, only: [:show]

  resources :lists do
    resources :list_games, only: [:create]
  end

  resources :list_games, only: [:destroy]

  resources :quizzes, only: [:show] do
    resources :quiz_games, only: [:create]
  end

  resources :quiz_games, only: [:destroy]

end
