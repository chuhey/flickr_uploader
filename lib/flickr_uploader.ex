defmodule FlickrUploader do
  use HTTPoison

  def main(args) do
    IO.puts "hello"
    HTTPoison.start
    HTTPoison.get! "https://www.flickr.com/services/oauth/request_token"
  end
end
