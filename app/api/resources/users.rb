module Resources
  class Users < Grape::API

    resource :users do
      desc 'Get all Users'
      get do
        users = User.all
        present users, with: Entities::User
      end

      desc 'returns a single user'
      route_param :id, type: Integer do
        get do
          user = User.find_by(id: params[:id])
          present user, with: Entities::User
        end
      end

      desc 'Creates a User'
      params do
        requires :name, type: String
        requires :age, type: Integer
        optional :gender, type: String
      end
      post :create do
        User.create(declared(params))
      end

      desc 'Handshakes with slack'
      params do
        requires :token, type: String
        requires :challenge, type: String
        requires :type, type: String
      end
      post :accept_challenge do
        status 200
        { 'challenge': params[:challenge] }

      end
    end
  end
end
