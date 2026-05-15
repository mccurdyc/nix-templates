use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[arg(global = true, long, value_name = "FILE")]
    config: Option<PathBuf>,

    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    Greet {
        #[arg(long, default_value = "World")]
        name: Option<String>,
    },
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Command::Greet { name } => {
            if let Some(name) = name {
                println!("Hello, {}!", name);
            } else {
                println!("Hello!");
            }
        }
    }
}
