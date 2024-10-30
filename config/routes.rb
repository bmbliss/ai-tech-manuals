Rails.application.routes.draw do
  resources :manuals do
    resources :sections do
      collection do
        get :search
        post :summarize
      end
      
      member do
        post :generate_content
      end
    end
  end
  root 'manuals#index'
end
