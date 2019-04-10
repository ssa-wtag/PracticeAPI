module Resources
  class Base < Grape::API
    mount Resources::Users
  end
end
