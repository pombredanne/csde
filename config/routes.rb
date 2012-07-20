KCSD1::Application.routes.draw do
  post "benchmark/run"
  get "benchmark/run"  
  
  get "deployment/deploy"
  post "deployment/deploy"

  post "deployment/opscenter"

  get "deployment/clean"

  get "chef_node/check"
  get "chef_node/show_all"
  get "chef_node/stop_all"

  get "chef_node/start"
  post "chef_node/start"

  get "chef_node/create"
  post "chef_node/create"

  get "chef_node/configure"
  post "chef_node/configure"



  # get "chef_server/setup"
  # get "chef_server/check"
  # get "chef_server/start"
  # get "chef_server/stop"
  get "chef_server/go_to"



  get "dashboard/show"
  post "dashboard/show"

  post "dashboard/reset"

  get "configuration/edit_aws"
  post "configuration/edit_aws"

  root :to => "dashboard#show", :as => "dashboard"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
