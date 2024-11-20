import community/dns/porkbun
import envoy
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

const root_domain = "danielle.pet"

pub fn main() {
  let assert Ok(secret_api_key) = envoy.get("PORKBUN_SECRET_KEY")
  let assert Ok(api_key) = envoy.get("PORKBUN_API_KEY")

  let assert Ok(domains) = get_domains()

  let client = porkbun.new_client(secret_api_key, api_key)

  let assert Ok(records) =
    client
    |> porkbun.retrieve_records(domain: root_domain)

  // We only care about CNAME records
  let records =
    records
    |> list.filter_map(fn(record) {
      case record.type_ {
        "CNAME" -> Ok(#(record.name, record))
        _ -> Error(Nil)
      }
    })
    |> dict.from_list()

  dict.each(domains, fn(domain, target) {
    // Has the domain already been created?
    case records |> dict.get(domain <> "." <> root_domain) {
      // If the record exists and differs, update it
      Ok(record) if record.content != target -> {
        let assert Ok(Nil) =
          client
          |> porkbun.edit_record(
            domain: root_domain,
            id: record.id,
            name: domain,
            content: target,
          )

        io.println(
          "Updated: " <> domain <> "." <> root_domain <> " -> " <> target,
        )
      }
      // If the record exists and is the same skip it
      Ok(_) -> io.println("Skipped: " <> domain <> "." <> root_domain)
      // The domain is new so create it
      Error(Nil) -> {
        let assert Ok(Nil) =
          client
          |> porkbun.create_cname_record(
            domain: root_domain,
            name: domain,
            content: target,
          )

        io.println(
          "Created: " <> domain <> "." <> root_domain <> " -> " <> target,
        )
      }
    }
  })
}

fn get_domains() -> Result(Dict(String, String), simplifile.FileError) {
  use domains <- result.try(simplifile.read("DOMAINS"))

  Ok(
    domains
    |> string.split("\n")
    |> list.filter_map(fn(line) {
      string.trim(line)
      |> string.split_once(" ")
    })
    |> dict.from_list,
  )
}
