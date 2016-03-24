# keystone-bench
Keystone benchmarking tooling

Originally from Dolph Mathew's benchmarking script found here: https://gist.github.com/dolph/02c6d37f49596b3f4298/4eb9d223ca35efeea56e4b151fb933b9a2c713d9

Simplified and made a bit more user friendly.

Usage:

  * benchmark.sh <admin password> <host> - runs benchmarks against the specified host as the admin user. This is probably what you want to run.
  * revoke.sh - revokes N tokens, used to test the impact of revocations on performance
  * time_until_invalid.sh - how long it takes for a token marked invalid to stop working, previously used to find and expose a bug in Keystone
