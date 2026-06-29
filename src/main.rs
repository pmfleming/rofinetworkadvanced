fn main() {
    if let Err(err) = nm_api::run() {
        eprintln!("Error: {err:#}");
        std::process::exit(1);
    }
}
