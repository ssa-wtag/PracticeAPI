module CustomTokenResponse
  def body
    user_profile = User.find_by(id: @token.resource_owner_id)
    super.merge({
        status_code: 200,
        message: 'Successfully Signed In',
        profile: user_profile})
  end
end
