use clap::Parser;

#[derive(Parser)]
#[command(name = "calculator", version = "1.0.0", about = "A simple calculator CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(clap::Subcommand)]
enum Commands {
    /// Add two numbers
    Add { a: f64, b: f64 },
    /// Subtract b from a
    Sub { a: f64, b: f64 },
    /// Multiply two numbers
    Mul { a: f64, b: f64 },
    /// Divide a by b
    Div { a: f64, b: f64 },
}

fn main() {
    let cli = Cli::parse();

    let result = match cli.command {
        Commands::Add { a, b } => a + b,
        Commands::Sub { a, b } => a - b,
        Commands::Mul { a, b } => a * b,
        Commands::Div { a, b } => {
            if b == 0.0 {
                eprintln!("Error: division by zero");
                std::process::exit(1);
            }
            a / b
        }
    };

    println!("{result}");
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_basic_math() {
        assert_eq!(2.0 + 3.0, 5.0);
        assert_eq!(10.0 - 4.0, 6.0);
        assert_eq!(3.0 * 7.0, 21.0);
        assert_eq!(15.0 / 3.0, 5.0);
    }
}
