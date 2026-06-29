use anyhow::Result;
use clap::Parser;

use crate::actions;
use crate::cli::{Cli, Command, DebugCommand};
use crate::list::print_enriched_network_list;
use crate::logging;
use crate::nm::Nm;

pub fn run() -> Result<()> {
    let Cli {
        verbose,
        log_file,
        command,
    } = Cli::parse();
    let log_path = logging::init(verbose, log_file.clone())?;
    tracing::debug!(path = %log_path.display(), "using log file");

    match command {
        Command::Networks(options) => with_nm(|nm| {
            print_enriched_network_list(
                nm,
                options.cached,
                options.refresh_cache,
                options.refresh_timeout,
                verbose,
                &log_file,
            )
        })?,
        Command::Scan(options) => with_nm(|nm| actions::run_scan(nm, options))?,
        Command::Connect(options) => with_nm(|nm| actions::connect_ssid(nm, options))?,
        Command::ConnectTarget(options) => with_nm(|nm| actions::connect_target(nm, options))?,
        Command::Saved => with_nm(actions::print_saved_profiles)?,
        Command::Profile { command } => with_nm(|nm| actions::run_profile_command(nm, command))?,
        Command::Status => with_nm(actions::print_status)?,
        Command::Disconnect => with_nm(actions::disconnect)?,
        Command::Connectivity => with_nm(actions::print_connectivity_state)?,
        Command::Debug { command } => match command {
            DebugCommand::Diagnose { json } => {
                with_nm(|nm| crate::diagnose::print_diagnosis(nm, json))?
            }
            DebugCommand::ContractFixture => crate::contract::print_shelllist_contract_fixture()?,
            DebugCommand::ContractFixtures => crate::contract::print_method_contract_fixtures()?,
        },
    }

    Ok(())
}

fn with_nm<T>(f: impl FnOnce(&Nm) -> Result<T>) -> Result<T> {
    let nm = Nm::new()?;
    f(&nm)
}
