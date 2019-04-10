class User < ApplicationRecord

  has_many :access_tokens, class_name: 'Doorkeeper::AccessToken',
                           foreign_key: :resource_owner_id,
                           dependent: :delete_all

  def self.authenticate(name)
    User.find_by(name: name)
  end
end
