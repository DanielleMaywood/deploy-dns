import decode/zero
import gleam/http
import gleam/http/request
import gleam/httpc.{type HttpError}
import gleam/json
import gleam/result

pub opaque type Client {
  Client(secret_api_key: String, api_key: String)
}

pub fn new_client(
  secret_api_key secret_api_key: String,
  api_key api_key: String,
) -> Client {
  Client(secret_api_key:, api_key:)
}

pub type PorkbunError {
  HttpError(HttpError)
  Failure
  UnexpectedResponse
}

pub type Record {
  Record(id: String, name: String, type_: String, content: String)
}

pub fn retrieve_records(
  client: Client,
  domain domain: String,
) -> Result(List(Record), PorkbunError) {
  let body =
    json.object([
      #("secretapikey", json.string(client.secret_api_key)),
      #("apikey", json.string(client.api_key)),
    ])
    |> json.to_string

  let request =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_scheme(http.Https)
    |> request.set_host("api.porkbun.com")
    |> request.set_path("/api/json/v3/dns/retrieve/" <> domain)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)

  use response <- result.try(httpc.send(request) |> result.map_error(HttpError))

  let decoder = {
    use records <- zero.field(
      "records",
      zero.list({
        use id <- zero.field("id", zero.string)
        use name <- zero.field("name", zero.string)
        use type_ <- zero.field("type", zero.string)
        use content <- zero.field("content", zero.string)

        zero.success(Record(id:, name:, type_:, content:))
      }),
    )

    zero.success(records)
  }

  case json.decode(response.body, zero.run(_, decoder)) {
    Ok(records) -> Ok(records)
    Error(_) -> Error(UnexpectedResponse)
  }
}

pub fn create_cname_record(
  client: Client,
  domain domain: String,
  name name: String,
  content content: String,
) -> Result(Nil, PorkbunError) {
  let body =
    json.object([
      #("secretapikey", json.string(client.secret_api_key)),
      #("apikey", json.string(client.api_key)),
      #("name", json.string(name)),
      #("type", json.string("CNAME")),
      #("content", json.string(content)),
      #("ttl", json.string("600")),
    ])
    |> json.to_string

  let request =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_scheme(http.Https)
    |> request.set_host("api.porkbun.com")
    |> request.set_path("/api/json/v3/dns/create/" <> domain)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)

  use response <- result.try(httpc.send(request) |> result.map_error(HttpError))

  let decoder = {
    use success <- zero.field("status", zero.string)

    zero.success(success)
  }

  case json.decode(response.body, zero.run(_, decoder)) {
    Ok("SUCCESS") -> Ok(Nil)
    Ok("ERROR") -> Error(Failure)
    Ok(_) | Error(_) -> Error(UnexpectedResponse)
  }
}

pub fn edit_record(
  client: Client,
  domain domain: String,
  id id: String,
  name name: String,
  content content: String,
) -> Result(Nil, PorkbunError) {
  let body =
    json.object([
      #("secretapikey", json.string(client.secret_api_key)),
      #("apikey", json.string(client.api_key)),
      #("name", json.string(name)),
      #("type", json.string("CNAME")),
      #("content", json.string(content)),
      #("ttl", json.string("600")),
    ])
    |> json.to_string

  let request =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_scheme(http.Https)
    |> request.set_host("api.porkbun.com")
    |> request.set_path("/api/json/v3/dns/edit/" <> domain <> "/" <> id)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)

  use response <- result.try(httpc.send(request) |> result.map_error(HttpError))

  let decoder = {
    use success <- zero.field("status", zero.string)

    zero.success(success)
  }

  case json.decode(response.body, zero.run(_, decoder)) {
    Ok("SUCCESS") -> Ok(Nil)
    Ok("ERROR") -> Error(Failure)
    Ok(_) | Error(_) -> Error(UnexpectedResponse)
  }
}
