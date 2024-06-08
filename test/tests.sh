# Here you write the tests
# And run them using test/run_tests.sh
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/../src:$PATH"
}

@test "Running and Stopping API" {
  run bin/run_api.sh start
  assert_output --partial "[+] Server is up and running!"
  refute_output --partial 'error'
  refute_output --partial 'ERROR'

  bin/run_api.sh stop

  run docker compose -f docker-compose_api.yml ps
  assert_output "NAME      IMAGE     COMMAND   SERVICE   CREATED   STATUS    PORTS"

  bin/run_api.sh clean

  run docker compose -f docker-compose_api.yml ps -a
  assert_output "NAME      IMAGE     COMMAND   SERVICE   CREATED   STATUS    PORTS"
}
