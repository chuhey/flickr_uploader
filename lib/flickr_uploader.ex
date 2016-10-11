defmodule FlickrUploader do
  require HTTPoison
  @api_key "0c7908a82895da73015e585632fe584b"
  @secret "a74bfb483be673aa"
  @callback_url "http://localhost/"
  @request_token_url "https://www.flickr.com/services/oauth/request_token"
  @user_auth_url "https://www.flickr.com/services/oauth/authorize"
  @access_token_url "https://www.flickr.com/services/oauth/access_token"
  @upload_url "https:/www.flickr.com/services/upload/"
 
  def main(args \\ []) do
    # 1. Getting a Request Token
    creds = OAuther.credentials(consumer_key: @api_key, consumer_secret: @secret, method: :hmac_sha1)
    params = OAuther.sign("get", @request_token_url, [{"oauth_callback", @callback_url}], creds)
    {:ok, response} = HTTPoison.get(@request_token_url, [], [params: params])
    request_token = response.body
                 |> String.split("&")
                 |> Enum.map(fn(x) -> String.split(x, "=") end)
                 |> Enum.map(fn([x,y]) -> {String.to_atom(x), y} end)
    oauth_token = request_token[:oauth_token]
    oauth_token_secret = request_token[:oauth_token_secret]

    # 2. Getting the User Authorization ( use dummy application url )
    {:ok, response} = HTTPoison.get(@user_auth_url, [], [params: [{"oauth_token", oauth_token}]])
    {_, location} = response.headers |> Enum.find(fn({x,_}) -> x == "location" end)
    IO.puts "Open your browser and access to below url. And input oauth_verifier."
    IO.puts location
    oauth_verifier = IO.gets(:stdio, "OAuth verifier : ")

    # 3. Exchange the Request Token for an Access Token
    creds2 = OAuther.credentials(
      consumer_key: @api_key, 
      consumer_secret: @secret, 
      method: :hmac_sha1, 
      token: oauth_token, 
      token_secret: oauth_token_secret)
    params3 = OAuther.sign("get", @access_token_url, [{"oauth_verifier", String.trim(oauth_verifier)}], creds2)
    IO.inspect params3
    {:ok, response} = HTTPoison.get(@access_token_url, [], [params: params3])
    IO.inspect response
  end
end
