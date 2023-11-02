cluster_name = "example"
eks_cluster_arn = "arn:aws:eks:us-east-1:261888767418:cluster/example"


namespace_pod_secrets = {
  fin3-dev = {
    bankadapter  = [
      "fin3-dev-jha-cred-test-test"
    ]
    bis-server  = [
      "stellar-gcp-credentials-test-test"
    ] 
  }
  stellar-mainnet = {
    orchestration-service = [
      "stellar-mainnet-orchestration-service-creds-test-test",
      "stellar-mainnet-admin-user-private-key-test-test",
      "stellar-gcp-credentials-test-test"
    ] 
  }
  utbpreprod = {
    utb-admin = [
      "utbpreprod-fireblocks-key-test-test",
      "utbpreprod-utbadmin-test-test",
      "stellar-gcp-credentials-test-test"
    ]
    utb-segregated-account = [
      "utbpreprod-utb-segregated-account-test-test", 
      "utbpreprod-utb-segregated-account-fireblocks-key-test-test"
    ]
  }
}

