Rails.application.routes.draw do
  get "quizz_games/create"
  get "quizz_games/destroy"
  get "list_games/create"
  get "list_games/destroy"
  get "quizzs/index"
  get "quizzs/show"
  get "quizzs/new"
  get "quizzs/create"
  get "quizzs/edit"
  get "quizzs/update"
  get "quizzs/destroy"
  get "lists/index"
  get "lists/show"
  get "lists/new"
  get "lists/create"
  get "lists/edit"
  get "lists/update"
  get "lists/destroy"
  get "games/index"
  get "games/show"
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
