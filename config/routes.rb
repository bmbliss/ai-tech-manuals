Rails.application.routes.draw do
  resources :manuals do
    resources :sections, except: [:index, :show]
  end
  root 'manuals#index'
end
