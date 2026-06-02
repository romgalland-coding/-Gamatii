Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  get  'discover',     to: 'discover#index', as: :discover
  post 'discover',     to: 'discover#create'
  get  'discover/:id', to: 'discover#show',  as: :discover_list

  resources :games, only: [:show]

  resources :lists do
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
