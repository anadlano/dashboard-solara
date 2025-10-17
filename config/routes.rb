Rails.application.routes.draw do
  root 'dashboard#index'

  resources :dashboard, only: [:index] do
    collection do
      get :sync_data
    end
  end
end
