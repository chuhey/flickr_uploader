defmodule FlickrUploader do
  require HTTPoison
  @callback_url "http://localhost/"
  @request_token_url "https://www.flickr.com/services/oauth/request_token"
  @user_auth_url "https://www.flickr.com/services/oauth/authorize"
  @access_token_url "https://www.flickr.com/services/oauth/access_token"
  @upload_url "https:/www.flickr.com/services/upload/"

  # Get Flickr API Consumer Key from Configuration
  defp api_key() do
    Application.get_env(:flickr_uploader, :api_key)
  end

  # Get Flickr API Consumer Secret from Configuration
  defp secret() do
    Application.get_env(:flickr_uploader, :secret)
  end

  # parse flickr api response body. for Getting Request Body, Exchange the Request Token. 
  #  exchange from "param1=value1&param2=value2" to [param1: value1, param2: value2]
  defp parse_response(body) do
    body |> String.split("&") |> Enum.map(fn(x) -> String.split(x, "=") end) |> Enum.map(fn([x,y]) -> {String.to_atom(x), y} end)
  end

  # getting request token.
  #  return : [oauth_callback_confirmed: <true/false>, oauth_token: <oauth_token>, oauth_token_secret: <oauth_token_secret>]
  defp get_request_token(apikey, scrt) do
    creds = OAuther.credentials(consumer_key: apikey, consumer_secret: scrt, method: :hmac_sha1)
    params = OAuther.sign("get", @request_token_url, [{"oauth_callback", @callback_url}], creds)
    {:ok, response} = HTTPoison.get(@request_token_url, [], [params: params])
    parse_response(response.body)
  end

  # Exchange the Request Token for an Access Token.
  #  return : [fullname: <fullname>, oauth_token: <oauth_token>, oauth_token_secret: <oauth_token_secret>, user_nsid: <user_nsid>, username: <username>]
  defp exchange_to_access_token(apikey, scrt, oauth_token, oauth_token_secret, verifier) do
    creds = OAuther.credentials(
      consumer_key: apikey, 
      consumer_secret: scrt, 
      method: :hmac_sha1, 
      token: oauth_token, 
      token_secret: oauth_token_secret)
    params = OAuther.sign("get", @access_token_url, [{"oauth_verifier", verifier}], creds)
    {:ok, response} = HTTPoison.get(@access_token_url, [], [params: params])
    parse_response(response.body)
  end

  @doc "This is main function for Flickr Uploader Application."
  def main(args \\ []) do
    # 1. Getting a Request Token
    request_token = get_request_token(api_key, secret)
    oauth_token = request_token[:oauth_token]
    oauth_token_secret = request_token[:oauth_token_secret]

    # 2. Getting the User Authorization ( use dummy application url )
    {:ok, response} = HTTPoison.get(@user_auth_url, [], [params: [{"oauth_token", oauth_token}]])
    {_, location} = response.headers |> Enum.find(fn({x,_}) -> x == "location" end)
    IO.puts "Open your browser and access to below url. And input oauth_verifier."
    IO.puts location
    oauth_verifier = IO.gets(:stdio, "OAuth verifier : ") |> String.trim

    # 3. Exchange the Request Token for an Access Token
    access_token = exchange_to_access_token(api_key, secret, oauth_token, oauth_token_secret, oauth_verifier)
    IO.inspect access_token

    # TODO use Flickr API with access token.
  end
end
