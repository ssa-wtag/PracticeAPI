require 'doorkeeper/grape/helpers'
module API
  class Dispatch < Grape::API
    helpers Doorkeeper::Grape::Helpers
    format :json

    before do
      #doorkeeper_authorize!
    end
    mount Resources::Base

    route :any, '*path' do
      error!({ error:  'Not Found',
               details: "No such route '#{request.path}'",
               status: 404 },
             404)
    end
  end
end
