Rails.application.routes.draw do
  resources :manuals do
    resources :sections, except: [:index, :show] do
      post :insert, on: :collection
    end
  end
  root 'manuals#index'
end
