require 'spec_helper'

describe Doorkeeper::TokensController do
  describe 'when authorization has succeeded' do
    let(:token) { double(:token, authorize: true) }

    it 'returns the authorization' do
      skip 'verify need of these specs'

      expect(token).to receive(:authorization)

      post :create
    end
  end

  describe 'when authorization has failed' do
    it 'returns the error response' do
      token = double(:token, authorize: false)
      allow(controller).to receive(:token) { token }

      post :create

      expect(response.status).to eq 401
      expect(response.headers['WWW-Authenticate']).to match(/Bearer/)
    end
  end

  describe 'when there is a failure due to a custom error' do
    it 'returns the error response with a custom message' do
      # I18n looks for `doorkeeper.errors.messages.custom_message` in locale files
      custom_message = "my_message"
      allow(I18n).to receive(:translate)
        .with(
          custom_message,
          hash_including(scope: %i[doorkeeper errors messages])
        )
        .and_return('Authorization custom message')

      doorkeeper_error = Doorkeeper::Errors::DoorkeeperError.new(custom_message)

      strategy = double(:strategy)
      request = double(token_request: strategy)
      allow(strategy).to receive(:authorize).and_raise(doorkeeper_error)
      allow(controller).to receive(:server).and_return(request)

      post :create

      expected_response_body = {
        "error"             => custom_message,
        "error_description" => "Authorization custom message"
      }
      expect(response.status).to eq 401
      expect(response.headers['WWW-Authenticate']).to match(/Bearer/)
      expect(JSON.parse(response.body)).to eq expected_response_body
    end
  end

  # http://tools.ietf.org/html/rfc7009#section-2.2
  describe 'revoking tokens' do
    let(:client) { FactoryBot.create(:application) }
    let(:access_token) { FactoryBot.create(:access_token, application: client) }

    before(:each) do
      allow(controller).to receive(:token) { access_token }
    end

    context 'when associated app is public' do
      let(:client) { FactoryBot.create(:application, confidential: false) }

      it 'returns 200' do
        post :revoke

        expect(response.status).to eq 200
      end

      it 'revokes the access token' do
        post :revoke

        expect(access_token.reload).to have_attributes(revoked?: true)
      end
    end

    context 'when associated app is confidential' do
      let(:client) { FactoryBot.create(:application, confidential: true) }
      let(:oauth_client) { Doorkeeper::OAuth::Client.new(client) }

      before(:each) do
        allow_any_instance_of(Doorkeeper::Server).to receive(:client) { oauth_client }
      end

      it 'returns 200' do
        post :revoke

        expect(response.status).to eq 200
      end

      it 'revokes the access token' do
        post :revoke

        expect(access_token.reload).to have_attributes(revoked?: true)
      end

      context 'when authorization fails' do
        let(:some_other_client) { FactoryBot.create(:application, confidential: true) }
        let(:oauth_client) { Doorkeeper::OAuth::Client.new(some_other_client) }

        it 'returns 200' do
          post :revoke

          expect(response.status).to eq 200
        end

        it 'does not revoke the access token' do
          post :revoke

          expect(access_token.reload).to have_attributes(revoked?: false)
        end
      end
    end
  end

  describe 'authorize response memoization' do
    it "memoizes the result of the authorization" do
      strategy = double(:strategy, authorize: true)
      expect(strategy).to receive(:authorize).once
      allow(controller).to receive(:strategy) { strategy }
      allow(controller).to receive(:create) do
        2.times { controller.send :authorize_response }
        controller.render json: {}, status: :ok
      end

      post :create
    end
  end

  describe 'when requested token introspection' do
    context 'authorized using Bearer token' do
      let(:client) { FactoryBot.create(:application) }
      let(:access_token) { FactoryBot.create(:access_token, application: client) }

      it 'responds with full token introspection' do
        request.headers['Authorization'] = "Bearer #{access_token.token}"

        post :introspect, params: { token: access_token.token }

        should_have_json 'active', true
        expect(json_response).to include('client_id', 'token_type', 'exp', 'iat')
      end
    end

    context 'authorized using Client Authentication' do
      let(:client) { FactoryBot.create(:application) }
      let(:access_token) { FactoryBot.create(:access_token, application: client) }

      it 'responds with full token introspection' do
        request.headers['Authorization'] = basic_auth_header_for_client(client)

        post :introspect, params: { token: access_token.token }

        should_have_json 'active', true
        expect(json_response).to include('client_id', 'token_type', 'exp', 'iat')
        should_have_json 'client_id', client.uid
      end
    end

    context 'public access token' do
      let(:client) { FactoryBot.create(:application) }
      let(:access_token) { FactoryBot.create(:access_token, application: nil) }

      it 'responds with full token introspection' do
        request.headers['Authorization'] = basic_auth_header_for_client(client)

        post :introspect, params: { token: access_token.token }

        should_have_json 'active', true
        expect(json_response).to include('client_id', 'token_type', 'exp', 'iat')
        should_have_json 'client_id', nil
      end
    end

    context 'token was issued to a different client than is making this request' do
      let(:client) { FactoryBot.create(:application) }
      let(:different_client) { FactoryBot.create(:application) }
      let(:access_token) { FactoryBot.create(:access_token, application: client) }

      it 'responds with only active state' do
        request.headers['Authorization'] = basic_auth_header_for_client(different_client)

        post :introspect, params: { token: access_token.token }

        expect(response).to be_successful

        should_have_json 'active', false
        expect(json_response).not_to include('client_id', 'token_type', 'exp', 'iat')
      end
    end

    context 'using invalid credentials to authorize' do
      let(:client) { double(uid: '123123', secret: '666999') }
      let(:access_token) { FactoryBot.create(:access_token) }

      it 'responds with invalid_client error' do
        request.headers['Authorization'] = basic_auth_header_for_client(client)

        post :introspect, params: { token: access_token.token }

        expect(response).not_to be_successful
        response_status_should_be 401

        should_not_have_json 'active'
        should_have_json 'error', 'invalid_client'
      end
    end

    context 'using wrong token value' do
      let(:client) { FactoryBot.create(:application) }
      let(:access_token) { FactoryBot.create(:access_token, application: client) }

      it 'responds with only active state' do
        request.headers['Authorization'] = basic_auth_header_for_client(client)

        post :introspect, params: { token: SecureRandom.hex(16) }

        should_have_json 'active', false
        expect(json_response).not_to include('client_id', 'token_type', 'exp', 'iat')
      end
    end

    context 'when requested Access Token expired' do
      let(:client) { FactoryBot.create(:application) }
      let(:access_token) { FactoryBot.create(:access_token, application: client, created_at: 1.year.ago) }

      it 'responds with only active state' do
        request.headers['Authorization'] = basic_auth_header_for_client(client)

        post :introspect, params: { token: access_token.token }

        should_have_json 'active', false
        expect(json_response).not_to include('client_id', 'token_type', 'exp', 'iat')
      end
    end

    context 'when requested Access Token revoked' do
      let(:client) { FactoryBot.create(:application) }
      let(:access_token) { FactoryBot.create(:access_token, application: client, revoked_at: 1.year.ago) }

      it 'responds with only active state' do
        request.headers['Authorization'] = basic_auth_header_for_client(client)

        post :introspect, params: { token: access_token.token }

        should_have_json 'active', false
        expect(json_response).not_to include('client_id', 'token_type', 'exp', 'iat')
      end
    end

    context 'unauthorized (no bearer token or client credentials)' do
      let(:access_token) { FactoryBot.create(:access_token) }

      it 'responds with invalid_request error' do
        post :introspect, params: { token: access_token.token }

        expect(response).not_to be_successful
        response_status_should_be 401

        should_not_have_json 'active'
        should_have_json 'error', 'invalid_request'
      end
    end
  end
end
