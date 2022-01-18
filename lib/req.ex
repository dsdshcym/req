defmodule Req do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @type url() :: URI.t() | String.t()

  @type method() :: :get | :post | :put | :delete

  @doc """
  Makes a GET request.

  See `request/3` for a list of supported options.
  """
  @spec get!(url(), keyword()) :: Req.Response.t()
  def get!(url, options \\ []) do
    request!(:get, url, options)
  end

  @doc """
  Makes a POST request.

  See `request/3` for a list of supported options.
  """
  @spec post!(url(), body :: term(), keyword()) :: Req.Response.t()
  def post!(url, body, options \\ []) do
    options = Keyword.put(options, :body, body)
    request!(:post, url, options)
  end

  @doc """
  Makes a PUT request.

  See `request/3` for a list of supported options.
  """
  @spec put!(url(), body :: term(), keyword()) :: Req.Response.t()
  def put!(url, body, options \\ []) do
    options = Keyword.put(options, :body, body)
    request!(:put, url, options)
  end

  @doc """
  Makes a DELETE request.

  See `request/3` for a list of supported options.
  """
  @spec delete!(url(), keyword()) :: Req.Response.t()
  def delete!(url, options \\ []) do
    request!(:delete, url, options)
  end

  @doc """
  Makes an HTTP request.

  ## Options

  Request method and URL:

    * `:method` - sets the request method

    * `:url` - sets the request URL

    * `:base_url` - sets base URL ([`put_base_url`](`Req.Steps.put_base_url/2`) step)

    * `:params` - adds params to request query string ([`put_params`](`Req.Steps.put_params/2`) step)

  Request headers:

    * `:headers` - sets request headers ([`encode_headers`](`Req.Steps.encode_headers/1`) step)

    * `:auth` - sets request authentication ([`auth`](`Req.Steps.auth/2`) step)

    * `:netrc` - if set, loads a `.netrc` file ([`load_netrc`](`Req.Steps.load_netrc/2`) step). Can be set to an atom `true` for the default
      path or to a string for a custom path to the file.

    * `:range` - sets the "Range" request header ([`put_range`](`Req.Steps.put_range/2`) step)

  Request body:

    * `:body` - sets request body ([`encode_body`](`Req.Steps.encode_body/1`) step)

  Response body:

    * `:raw` - if set, returns raw response body (by disabling [`decompress_body`](`Req.Steps.decompress_body/1`) and [`decode_body`](`Req.Steps.decode_body/1`) steps)

  Response redirects ([`follow_redirects`](`Req.Steps.follow_redirects/2`) step):

    * `:location_trusted` - by default, authorization credentials are only sent on redirects to the same host. If set to `true`, credentials will be sent to any host.

    * `:max_redirects` - the maximum number of redirects, defaults to `50`. Set to `0` to disable automatic redirects.

  Response/error retries ([`retry`](`Req.Steps.retry/2`) step):

    * `:retry_delay` - the delay in milliseconds between retry attempts.

    * `:max_retries` - the maximum number of retries, defaults to `2` (for a total of `3` requests to the server, including the initial one.)

  Cache options ([`cache`](`Req.Steps.put_if_modified_since/2`) step):

    * `:cache` - if `true`, enables HTTP caching. Defaults to `false`.

    * `:cache_dir` - the directory to store the cache, defaults to `<user_cache_dir>/req` (see: `:filename.basedir/3`)

  Finch options ([`run_finch`](`Req.Steps.run_finch/1`) step):

    * `:finch` - the name of the Finch pool to use. Defaults to `Req.Finch` which is automatically started.

    * `:pool_timeout` - the maximum allowed time in milliseconds to get a connection from the pool, defaults to `5000`.

    * `:receive_timeout` - the maximum allowed time in milliseconds to receive a response from the socket, defaults to `15000`.

  """
  @spec request(url(), Keyword.t()) :: {:ok, Req.Response.t()} | {:error, Exception.t()}
  def request(_url, options \\ []) do
    method = :get
    options = Keyword.merge(default_options(), options)

    method
    |> Req.Request.build(options[:url], options)
    |> Req.Steps.put_default_steps(options)
    |> Req.Request.run()
  end

  @doc """
  Makes an HTTP request and returns a response or raises an error.

  See `request/3` for more information.
  """
  @spec request!(method(), url(), keyword()) :: Req.Response.t()
  def request!(method, url, options \\ []) do
    options = Keyword.merge(default_options(), options)

    method
    |> Req.Request.build(url, options)
    |> Req.Steps.put_default_steps(options)
    |> Req.Request.run!()
  end

  @doc """
  Returns default options.

  See `default_options/1` for more information.
  """
  @spec default_options() :: keyword()
  def default_options() do
    Application.get_env(:req, :default_options, [])
  end

  @doc """
  Sets default options.

  The default options are used by `get!/2`, `post!/3`, `put!/3`,
  `delete!/2`, `request/3`, and `request!/3` functions.

  Avoid setting default options in libraries as they are global.
  """
  @spec default_options(keyword()) :: :ok
  def default_options(options) do
    Application.put_env(:req, :default_options, options)
  end
end
