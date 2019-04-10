module Entities
  class User < Shared::Entities::Base
    expose :name
    expose :age
  end
end
