import Config

# Configure Joken for JWT signing
config :joken,
  default_signer: [
    signer_alg: "HS256",
    key_octet: "your_super_secret_key_that_should_be_at_least_256_bits_long_for_security"
  ]

# Configure libcluster
config :libcluster,
  topologies: [
    elixir_test: [
      # The gossip strategy is used for local development
      # For production, you might want to use a different strategy
      # like Cluster.Strategy.Kubernetes or Cluster.Strategy.DNSPoll
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45892,
        if_addr: "0.0.0.0",
        multicast_addr: "230.1.1.1",
        multicast_ttl: 1,
        broadcast_only: false
      ]
    ]
  ]
