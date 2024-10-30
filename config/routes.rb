Rails.application.routes.draw do
  resources :manuals
  root 'manuals#index'
end
